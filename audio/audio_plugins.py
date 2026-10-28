#!/usr/bin/env python3
"""Manage vendor installers outside the Nix store. No actions on import."""
import argparse
import contextlib
import hashlib
import json
import os
import platform
from pathlib import Path
import plistlib
import re
import shutil
import subprocess
import sys
import tempfile
from urllib.parse import urlsplit
import zipfile

SUFFIXES = {'.component': 'AU', '.vst': 'VST2', '.vst3': 'VST3', '.aaxplugin': 'AAX', '.dpm': 'RTAS'}
ROOTS = ['~/Library/Audio/Plug-Ins', '/Library/Audio/Plug-Ins',
         '/Library/Application Support/Avid/Audio/Plug-Ins',
         '~/Library/Application Support/Avid/Audio/Plug-Ins',
         '/Library/Application Support/Digidesign/Plug-Ins']
BASE = Path(__file__).resolve().parent


def read_json(path):
    return json.loads(Path(path).read_text())


def bundle(path, kind=None):
    path = Path(path)
    try:
        with (path / 'Contents/Info.plist').open('rb') as f:
            info = plistlib.load(f)
    except (OSError, ValueError, plistlib.InvalidFileException):
        info = {}
    architectures = []
    executable = info.get('CFBundleExecutable')
    if executable and Path('/usr/bin/lipo').exists():
        result = subprocess.run(['/usr/bin/lipo', '-archs', str(path / 'Contents/MacOS' / executable)],
                                capture_output=True, text=True)
        if result.returncode == 0:
            architectures = result.stdout.strip().split()
    return {'path': str(path), 'name': path.name, 'format': kind or SUFFIXES.get(path.suffix, 'AUv3'),
            'id': info.get('CFBundleIdentifier'),
            'architectures': architectures,
            'version': info.get('CFBundleShortVersionString', info.get('CFBundleVersion'))}


def inventory(roots=None, app_roots=None):
    found = {}
    for root in roots if roots is not None else ROOTS:
        for base, dirs, _ in os.walk(Path(root).expanduser()):
            for name in dirs[:]:
                path = Path(base) / name
                if path.suffix.lower() in SUFFIXES:
                    dirs.remove(name)
                    found[str(path)] = bundle(path)
    # AUv3 extensions live inside apps, rather than the traditional plugin folders.
    for root in app_roots if app_roots is not None else ['/Applications', '~/Applications']:
        for base, dirs, _ in os.walk(Path(root).expanduser()):
            # Avoid frameworks, resources and sample content while retaining nested app folders.
            dirs[:] = [d for d in dirs if d not in ('Resources', 'Frameworks', 'MacOS', '_CodeSignature')]
            for name in dirs[:]:
                if not name.endswith('.appex'):
                    continue
                path = Path(base) / name
                dirs.remove(name)
                try:
                    with (path / 'Contents/Info.plist').open('rb') as f:
                        info = plistlib.load(f)
                    if 'AudioUnit' in info.get('NSExtension', {}).get('NSExtensionPointIdentifier', ''):
                        found[str(path)] = bundle(path, 'AUv3')
                except (OSError, ValueError, plistlib.InvalidFileException):
                    pass
    return sorted(found.values(), key=lambda r: r['path'])


def status(product, current, formats=None):
    rows = []
    for expected in product['bundles']:
        if formats and expected['format'] not in formats:
            continue
        # IDs alone are insufficient: some vendors reuse them across AU/VST/VST3.
        matches = [r for r in current if r['format'] == expected['format'] and
                   r['name'] == expected['name'] and r['id'] == expected['id']]
        exact = [r for r in matches if r['version'] == expected['version'] and
                 (not product.get('architecture') or product['architecture'] in r.get('architectures', []))]
        state = 'missing' if not matches else ('ok' if len(matches) == 1 and exact else 'drift')
        rows.append({'bundle': expected['name'], 'state': state,
                     'wanted': expected['version'], 'installed': matches})
    return rows


def digest(path):
    h = hashlib.sha256()
    with Path(path).open('rb') as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b''):
            h.update(chunk)
    return h.hexdigest()


def validate_recipe(recipe):
    if recipe['kind'] not in ('pkg', 'dmg', 'zip'):
        raise ValueError('Installer kind must be pkg, dmg or zip')
    if not re.fullmatch(r'[0-9a-f]{64}', recipe['sha256']):
        raise ValueError('Installer requires a hexadecimal SHA-256')
    team = recipe.get('teamId')
    certificate = recipe.get('certificateSha256')
    if bool(team) == bool(certificate):
        raise ValueError('Pin exactly one vendor Team ID or legacy signing certificate SHA-256')
    if team and not re.fullmatch(r'[A-Z0-9]{10}', team):
        raise ValueError('Invalid vendor Team ID')
    if certificate and not re.fullmatch(r'[0-9a-f]{64}', certificate):
        raise ValueError('Invalid signing certificate SHA-256')
    if recipe.get('url'):
        u = urlsplit(recipe['url'])
        if u.scheme != 'https' or not u.hostname or u.username or u.password or u.query or u.fragment:
            raise ValueError('Use a public HTTPS vendor URL without credentials, query or fragment; import private downloads with --file')
    if recipe['kind'] != 'pkg':
        member = Path(recipe.get('member', ''))
        if not recipe.get('member') or member.is_absolute() or '..' in member.parts or member.suffix not in ('.pkg', '.app'):
            raise ValueError('DMG/ZIP requires an explicit relative .pkg or installer .app member')


def run(args, **kwargs):
    return subprocess.run([str(x) for x in args], check=True, **kwargs)


def fetch(recipe, local=None):
    validate_recipe(recipe)
    cache = Path.home() / 'Library/Caches/nix-audio'
    cache.mkdir(parents=True, exist_ok=True, mode=0o700)
    target = cache / (recipe['sha256'] + '.' + recipe['kind'])
    if target.is_file() and digest(target) == recipe['sha256']:
        return target
    with tempfile.TemporaryDirectory(prefix='download-', dir=cache) as tmp:
        staged = Path(tmp) / 'installer'
        if local:
            shutil.copyfile(Path(local).expanduser(), staged)
        else:
            if not recipe.get('url'):
                raise ValueError('Account download required: pass --file /path/to/vendor-installer')
            run(['/usr/bin/curl', '--fail', '--location', '--silent', '--show-error',
                 '--proto', '=https', '--proto-redir', '=https', '--connect-timeout', '30',
                 '--max-time', '1800', '--output', staged, recipe['url']])
        if digest(staged) != recipe['sha256']:
            raise ValueError('Installer checksum mismatch; nothing will be installed')
        os.chmod(staged, 0o600)
        os.replace(staged, target)
    return target


@contextlib.contextmanager
def package_payload(artifact, recipe):
    if recipe['kind'] == 'pkg':
        yield artifact
        return
    with tempfile.TemporaryDirectory(prefix='nix-audio-') as tmp:
        root = Path(tmp)
        mounted = False
        try:
            if recipe['kind'] == 'dmg':
                run(['/usr/bin/hdiutil', 'attach', artifact, '-readonly', '-nobrowse',
                     '-mountpoint', root, '-quiet'])
                mounted = True
            else:
                with zipfile.ZipFile(artifact) as archive:
                    for item in archive.infolist():
                        p = Path(item.filename)
                        if p.is_absolute() or '..' in p.parts or ((item.external_attr >> 16) & 0o170000) == 0o120000:
                            raise ValueError('Unsafe archive member')
                    archive.extractall(root)
            payload = root / recipe['member']
            valid_type = payload.is_file() if payload.suffix == '.pkg' else payload.is_dir()
            if not valid_type or not payload.resolve().is_relative_to(root.resolve()):
                raise ValueError('The specified flat .pkg or installer .app was not found')
            yield payload
        finally:
            if mounted:
                run(['/usr/bin/hdiutil', 'detach', root, '-quiet'])


def verify_package(path, recipe):
    if Path(path).suffix == '.app':
        if not recipe.get('teamId'):
            raise ValueError('Installer applications require a vendor Team ID')
        run(['/usr/bin/codesign', '--verify', '--deep', '--strict', path], capture_output=True)
        signature = run(['/usr/bin/codesign', '-dv', '--verbose=4', path], capture_output=True, text=True)
        if not re.search(r'^TeamIdentifier=' + re.escape(recipe['teamId']) + r'$', signature.stderr, re.M):
            raise ValueError('Installer app signer does not match the pinned vendor Team ID')
        run(['/usr/sbin/spctl', '--assess', '--type', 'execute', path], capture_output=True)
        return
    signature = run(['/usr/sbin/pkgutil', '--check-signature', path], capture_output=True, text=True)
    if recipe.get('teamId'):
        if not re.search(r'Developer ID Installer:.*\(' + re.escape(recipe['teamId']) + r'\)', signature.stdout):
            raise ValueError('Installer signer does not match the pinned vendor Team ID')
    else:
        fingerprint = re.search(r'1\. Developer ID Installer:.*?SHA256 Fingerprint:\s*((?:[A-F0-9]{2}\s+){31}[A-F0-9]{2})', signature.stdout, re.S)
        if not fingerprint or ''.join(fingerprint[1].split()).lower() != recipe['certificateSha256']:
            raise ValueError('Installer signing certificate differs from the pinned certificate')
    # Do not override Gatekeeper for legacy/expired installers.
    run(['/usr/sbin/spctl', '--assess', '--type', 'install', path], capture_output=True, text=True)


def install_license(mapping):
    reference = mapping['reference']
    if not reference.startswith('op://'):
        raise ValueError('License reference must be a 1Password op:// reference')
    destination = Path(mapping['destination']).expanduser()
    if not destination.is_absolute() or not destination.parent.is_dir() or destination.is_symlink():
        raise ValueError('Use an absolute license path with an existing parent and no destination symlink')
    # op stays in the interactive user session; never evaluate a secret in Nix.
    result = run(['op', 'read', '--no-newline', reference], capture_output=True)
    fd, temp = tempfile.mkstemp(prefix='.audio-license-', dir=destination.parent)
    try:
        with os.fdopen(fd, 'wb') as f:
            f.write(result.stdout)
        os.chmod(temp, 0o600)
        os.replace(temp, destination)
    finally:
        if os.path.exists(temp):
            os.unlink(temp)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--catalog', default=str(BASE / 'catalog.json'))
    parser.add_argument('--installers', default=str(BASE / 'installers.json'))
    sub = parser.add_subparsers(dest='command', required=True)
    inv = sub.add_parser('inventory', help='Read plugin bundle metadata; never reads licenses')
    inv.add_argument('--root', action='append', help='Override plugin search roots (repeatable)')
    inv.add_argument('--app-root', action='append', help='Override AUv3 app search roots')
    for name in ('status', 'plan'):
        p = sub.add_parser(name)
        p.add_argument('product', nargs='?')
        p.add_argument('--formats', nargs='+', choices=list(SUFFIXES.values()) + ['AUv3'])
        p.add_argument('--json', action='store_true')
    sub.add_parser('list')
    p = sub.add_parser('guide')
    p.add_argument('product')
    p.add_argument('--open', action='store_true', help='Open the vendor page')
    for name in ('fetch', 'install'):
        p = sub.add_parser(name)
        p.add_argument('product')
        p.add_argument('--file', help='Account-only vendor download matching the pinned hash')
        if name == 'install':
            p.add_argument('--apply', action='store_true', help='Execute the vendor installer with sudo')
    p = sub.add_parser('lock', help='Verify a downloaded vendor installer and write a recipe to an explicit lock file')
    p.add_argument('product')
    p.add_argument('--file', required=True)
    p.add_argument('--version', required=True, help='Vendor product version, verified by you')
    signer = p.add_mutually_exclusive_group(required=True)
    signer.add_argument('--team-id')
    signer.add_argument('--certificate-sha256', help='For legacy signatures without a Team ID')
    p.add_argument('--url', help='Optional public vendor download URL; never use personalized URLs')
    p.add_argument('--member', help='Relative flat .pkg or installer .app path inside a DMG/ZIP')
    p.add_argument('--output', required=True, help='Writable installers.json; never the Nix store')
    p = sub.add_parser('license-install', help='Place a vendor-supported license file from 1Password')
    p.add_argument('product')
    p.add_argument('--config', required=True, help='Runtime JSON mapping product IDs to reference/destination')
    p.add_argument('--apply', action='store_true')
    args = parser.parse_args(argv)
    if args.command == 'inventory':
        print(json.dumps(inventory(args.root, args.app_root), indent=2))
        return 0
    catalog = read_json(args.catalog)
    system = catalog.get('system', 'aarch64-darwin' if platform.machine() == 'arm64' else 'x86_64-darwin')
    # Flake packages receive a catalog selected by Nix's system attribute. This
    # fallback also makes direct source execution useful during development.
    catalog['products'] = [dict(p, **p['targets'][system]) if 'targets' in p else p for p in catalog['products']]
    products = {p['id']: p for p in catalog['products']}
    raw_installers = read_json(args.installers)
    installers = {key: value if 'version' in value else value[system]
                  for key, value in raw_installers.items() if 'version' in value or system in value}
    if hasattr(args, 'product') and args.product and args.product not in products:
        raise ValueError('Unknown product: ' + args.product)
    if args.command == 'list':
        for p in products.values():
            print(f"{p['id']:28} {p['version']:20} {p['vendor']}" +
                  ('' if p.get('supported', True) else ' [no native target]'))
        return 0
    if args.command in ('status', 'plan'):
        current = inventory()
        result = []
        for p in products.values():
            if args.product and args.product != p['id']:
                continue
            rows = status(p, current, args.formats)
            if not p.get('supported', True):
                rows = [{'bundle': p['name'], 'state': 'unsupported', 'wanted': p['version'], 'installed': []}]
            if not rows:
                continue
            recipe = installers.get(p['id'])
            result.append({'id': p['id'], 'bundles': rows, 'installer': 'pinned' if recipe else 'needs-vendor-download',
                           'license': p['license'], 'guide': p['source']['page'],
                           'system': system, 'version': p['version'],
                           'edition': recipe.get('edition') if recipe else None, 'reason': p.get('reason', '')})
        if args.json:
            print(json.dumps(result, indent=2))
        else:
            for r in result:
                counts = {s: sum(b['state'] == s for b in r['bundles']) for s in ('ok', 'missing', 'drift', 'unsupported')}
                print(f"{r['id']:28} {counts}  installer={r['installer']}")
                if args.command == 'plan':
                    print(f"  Target: {r['system']} / {r['version']}" + (f" / {r['edition']}" if r['edition'] else ''))
                    print(f"  Activation: {r['license']}\n  Vendor: {r['guide']}")
                    if r['reason']:
                        print('  ' + r['reason'])
        return int(args.command == 'status' and any(b['state'] != 'ok' for r in result for b in r['bundles']))
    p = products[args.product]
    if args.command == 'guide':
        print(json.dumps({'product': p['name'], 'source': p['source'], 'license': p['license'],
                          'target': {'system': system, 'version': p['version'],
                                     'supported': p.get('supported', True), 'reason': p.get('reason', '')},
                          'managers': catalog['managers']}, indent=2))
        if args.open:
            run(['/usr/bin/open', p['source']['page']])
    elif args.command == 'lock':
        artifact = Path(args.file).expanduser().resolve()
        if args.version != p['version']:
            raise ValueError('Version differs from catalog; review and update catalog bundle versions before pinning an upgrade')
        recipe = {'version': args.version, 'kind': artifact.suffix[1:].lower(), 'sha256': digest(artifact)}
        if args.team_id:
            recipe['teamId'] = args.team_id
        else:
            recipe['certificateSha256'] = args.certificate_sha256
        if args.url:
            recipe['url'] = args.url
        if args.member:
            recipe['member'] = args.member
        validate_recipe(recipe)
        with package_payload(artifact, recipe) as pkg:
            verify_package(pkg, recipe)
        dest = Path(args.output).expanduser().resolve()
        if str(dest).startswith('/nix/store/'):
            raise ValueError('Lock output must be outside the Nix store')
        data = read_json(dest) if dest.exists() else {}
        existing = data.get(p['id'], {})
        if 'version' in existing:
            raise ValueError('Lock output uses the old flat format; use a new per-system lock file')
        data.setdefault(p['id'], {})[system] = recipe
        dest.write_text(json.dumps(data, indent=2, sort_keys=True) + '\n')
        print('Pinned ' + p['id'] + '; verify installed bundle versions after installation.')
    elif args.command == 'license-install':
        mapping = read_json(args.config)[p['id']]
        if not args.apply:
            print('Would retrieve the configured 1Password file and write it with mode 0600. Use --apply.')
        else:
            install_license(mapping)
            print('License file placed. Vendor activation may still be required.')
    else:
        if not p.get('supported', True):
            print(f"No native {system} target for {p['name']}: {p.get('reason', '')}")
            return 2
        recipe = installers.get(p['id'])
        if not recipe:
            print(f"No verified installer pinned for {p['name']}.\n{p['source']['instructions']}\n{p['source']['page']}\nUse lock after downloading the official installer.")
            return 2
        validate_recipe(recipe)
        if recipe['version'] != p['version']:
            raise ValueError('Installer version and catalog version differ')
        if args.command == 'install':
            rows = status(p, inventory())
            if rows and all(r['state'] == 'ok' for r in rows):
                print('All cataloged bundles already match; no installation needed. Activation is not checked.')
                return 0
            if not args.apply:
                action = 'open its signed interactive vendor installer' if recipe.get('member', '').endswith('.app') else 'run its vendor .pkg with sudo'
                label = recipe.get('edition', p['name'])
                print(f"Would fetch and verify {label} {recipe['version']} for {system}, then {action}.\nUse --apply after closing Ableton and other audio hosts.\nActivation: {p['license']}")
                return 0
            if system == 'aarch64-darwin' and platform.machine() != 'arm64':
                raise ValueError('Run the Apple Silicon flake package from a native arm64 environment')
        artifact = fetch(recipe, args.file)
        with package_payload(artifact, recipe) as pkg:
            verify_package(pkg, recipe)
            if args.command == 'fetch':
                print(artifact)
                return 0
            if pkg.suffix == '.app':
                run(['/usr/bin/open', '-W', '-n', pkg])
            else:
                run(['/usr/bin/sudo', '/usr/sbin/installer', '-pkg', pkg, '-target', '/'])
        remaining = [r for r in status(p, inventory()) if r['state'] != 'ok']
        if remaining:
            print('Installer completed, but catalog verification found missing or differing bundles:')
            print(json.dumps(remaining, indent=2))
            return 3
        print('Installed bundles verified. Activation: ' + p['license'])
    return 0


if __name__ == '__main__':
    try:
        sys.exit(main())
    except (ValueError, OSError, KeyError, subprocess.CalledProcessError, zipfile.BadZipFile) as error:
        # Captured output (particularly op stdout/stderr) must never be printed.
        if isinstance(error, subprocess.CalledProcessError):
            program = Path(str(error.cmd[0])).name if isinstance(error.cmd, (list, tuple)) else 'external command'
            print(f'{program} failed (exit {error.returncode}); captured output withheld.', file=sys.stderr)
        else:
            print(str(error), file=sys.stderr)
        sys.exit(2)
