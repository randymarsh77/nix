import contextlib
import io
import json
import os
from pathlib import Path
import plistlib
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch
import zipfile

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import audio_plugins as audio


class ManagementTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)

    def recipe(self, **extra):
        return dict(version='1.0', kind='pkg', sha256='0' * 64, teamId='ABCDEFGHIJ', **extra)

    def make_bundle(self, root, name, version='1.0', identity='test.plugin'):
        path = root / name / 'Contents'
        path.mkdir(parents=True)
        with (path / 'Info.plist').open('wb') as f:
            plistlib.dump(dict(CFBundleIdentifier=identity, CFBundleShortVersionString=version), f)
        return audio.bundle(path.parent)

    def test_inventory_handles_spaces_nested_paths_and_corrupt_bundles(self):
        self.make_bundle(self.root / 'Vendor Name', 'My Synth.vst3')
        (self.root / 'Broken.component').mkdir()
        rows = audio.inventory([str(self.root)], [])
        self.assertEqual(len(rows), 2)
        self.assertEqual(rows[0]['version'], None)
        self.assertEqual(rows[1]['version'], '1.0')

    def test_auv3_inside_app_is_discovered(self):
        path = self.root / 'Example.app/Contents/PlugIns/Synth.appex/Contents'
        path.mkdir(parents=True)
        with (path / 'Info.plist').open('wb') as f:
            plistlib.dump({'NSExtension': {'NSExtensionPointIdentifier': 'com.apple.AudioUnit'},
                          'CFBundleIdentifier': 'sample.auv3'}, f)
        self.assertEqual(audio.inventory([], [str(self.root)])[0]['format'], 'AUv3')

    def test_status_distinguishes_formats_duplicates_and_versions(self):
        expected = self.make_bundle(self.root / 'system', 'Synth.vst3')
        p = {'bundles': [expected]}
        au = dict(expected, format='AU')
        self.assertEqual(audio.status(p, [au])[0]['state'], 'missing')
        self.assertEqual(audio.status(p, [expected])[0]['state'], 'ok')
        changed = dict(expected, version='2.0')
        self.assertEqual(audio.status(p, [changed])[0]['state'], 'drift')
        self.assertEqual(audio.status(p, [expected, changed])[0]['state'], 'drift')
        self.assertEqual(audio.status(p, [expected], ['AU']), [])

    def test_recipe_rejects_private_urls_and_unpinned_artifacts(self):
        for url in ['http://vendor.test/a.pkg', 'https://user:pass@vendor.test/a.pkg',
                    'https://vendor.test/a.pkg?token=secret', 'https://vendor.test/a.pkg#secret']:
            with self.assertRaises(ValueError):
                audio.validate_recipe(self.recipe(url=url))
        r = self.recipe(); r['sha256'] = ''
        with self.assertRaises(ValueError): audio.validate_recipe(r)
        r = self.recipe(); r.update(kind='dmg', member='../outside.pkg')
        with self.assertRaises(ValueError): audio.validate_recipe(r)

    def test_fetch_hash_mismatch_does_not_publish_artifact(self):
        source = self.root / 'vendor.pkg'; source.write_bytes(b'wrong installer')
        with patch.object(Path, 'home', return_value=self.root):
            with self.assertRaisesRegex(ValueError, 'checksum mismatch'):
                audio.fetch(self.recipe(), source)
        self.assertEqual(list((self.root / 'Library/Caches/nix-audio').glob('*.pkg')), [])

    def test_fetch_rechecks_corrupt_cache_and_imports_good_copy(self):
        source = self.root / 'vendor.pkg'; source.write_bytes(b'valid installer')
        r = self.recipe(); r['sha256'] = audio.digest(source)
        cache = self.root / 'Library/Caches/nix-audio'; cache.mkdir(parents=True)
        target = cache / (r['sha256'] + '.pkg'); target.write_bytes(b'corruption')
        with patch.object(Path, 'home', return_value=self.root):
            self.assertEqual(audio.fetch(r, source).read_bytes(), b'valid installer')

    def test_zip_rejects_traversal_and_symlinks(self):
        for name, mode in [('../evil.pkg', 0), ('link', 0o120777 << 16)]:
            artifact = self.root / 'bad.zip'
            with zipfile.ZipFile(artifact, 'w') as z:
                info = zipfile.ZipInfo(name); info.external_attr = mode
                z.writestr(info, 'payload')
            r = self.recipe(); r.update(kind='zip', member='installer.pkg')
            with self.assertRaises(ValueError):
                with audio.package_payload(artifact, r): pass
        self.assertFalse((self.root.parent / 'evil.pkg').exists())

    def test_zip_uses_only_explicit_payload(self):
        artifact = self.root / 'good.zip'
        with zipfile.ZipFile(artifact, 'w') as z:
            z.writestr('Vendor/Installer.pkg', b'package')
            z.writestr('Other.pkg', b'other')
        r = self.recipe(); r.update(kind='zip', member='Vendor/Installer.pkg')
        with audio.package_payload(artifact, r) as p:
            self.assertEqual(p.read_bytes(), b'package')
        self.assertFalse(p.exists())

    def test_wrong_signer_is_rejected_before_gatekeeper(self):
        with patch.object(audio, 'run', return_value=subprocess.CompletedProcess([], 0, stdout='Developer ID Installer: Someone (WRONGTEAM1)')) as run:
            with self.assertRaises(ValueError): audio.verify_package(self.root / 'a.pkg', self.recipe())
            self.assertEqual(run.call_count, 1)

    def test_gatekeeper_rejection_is_not_bypassed(self):
        results = [subprocess.CompletedProcess([], 0, stdout='Developer ID Installer: Vendor (ABCDEFGHIJ)'),
                   subprocess.CalledProcessError(1, ['spctl'])]
        with patch.object(audio, 'run', side_effect=results):
            with self.assertRaises(subprocess.CalledProcessError):
                audio.verify_package(self.root / 'a.pkg', self.recipe())

    def test_app_installer_checks_signature_team_and_gatekeeper(self):
        responses = [subprocess.CompletedProcess([], 0),
                     subprocess.CompletedProcess([], 0, stderr='TeamIdentifier=ABCDEFGHIJ\n'),
                     subprocess.CompletedProcess([], 0)]
        with patch.object(audio, 'run', side_effect=responses) as run:
            audio.verify_package(self.root / 'Install.app', self.recipe())
            self.assertEqual(run.call_count, 3)
            self.assertIn('--strict', run.call_args_list[0].args[0])
            self.assertIn('execute', run.call_args_list[2].args[0])

    def test_app_installer_wrong_team_is_rejected(self):
        responses = [subprocess.CompletedProcess([], 0),
                     subprocess.CompletedProcess([], 0, stderr='TeamIdentifier=WRONGTEAM1\n')]
        with patch.object(audio, 'run', side_effect=responses):
            with self.assertRaises(ValueError):
                audio.verify_package(self.root / 'Install.app', self.recipe())

    def test_license_write_is_private_and_preserves_bytes(self):
        dest = self.root / 'license.dat'
        secret = b'license\x00\n'
        with patch.object(audio, 'run', return_value=subprocess.CompletedProcess([], 0, stdout=secret)) as run:
            audio.install_license(dict(reference='op://Music/Plugin/file', destination=str(dest)))
            self.assertIn('--no-newline', run.call_args.args[0])
        self.assertEqual(dest.read_bytes(), secret)
        self.assertEqual(dest.stat().st_mode & 0o777, 0o600)

    def test_failed_license_fetch_preserves_existing_file(self):
        dest = self.root / 'license.dat'; dest.write_bytes(b'existing')
        with patch.object(audio, 'run', side_effect=subprocess.CalledProcessError(1, ['op'], output=b'secret')):
            with self.assertRaises(subprocess.CalledProcessError):
                audio.install_license(dict(reference='op://Music/Plugin/file', destination=str(dest)))
        self.assertEqual(dest.read_bytes(), b'existing')

    def test_license_symlink_is_rejected(self):
        dest = self.root / 'license'; dest.symlink_to(self.root / 'other')
        with self.assertRaises(ValueError):
            audio.install_license(dict(reference='op://Music/Plugin/file', destination=str(dest)))

    def test_install_default_does_not_download_or_execute(self):
        catalog = self.root / 'catalog.json'
        catalog.write_text(json.dumps({'products': [{'id': 'test', 'name': 'Test', 'version': '1.0',
                       'bundles': [{'name': 'Synth.vst3', 'format': 'VST3', 'id': 'synth', 'version': '1.0'}],
                       'license': 'Manual activation'}]}))
        installers = self.root / 'installers.json'
        installers.write_text(json.dumps({'test': self.recipe()}))
        with patch.object(audio, 'inventory', return_value=[]), patch.object(audio, 'fetch') as fetch, patch.object(audio, 'run') as run, contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(audio.main(['--catalog', str(catalog), '--installers', str(installers), 'install', 'test']), 0)
            fetch.assert_not_called(); run.assert_not_called()

    def test_catalog_and_installer_consistency(self):
        products = audio.read_json(audio.BASE / 'catalog.json')['products']
        ids = [p['id'] for p in products]
        self.assertEqual(len(ids), len(set(ids)))
        for key, recipes in audio.read_json(audio.BASE / 'installers.json').items():
            for system, r in recipes.items():
                audio.validate_recipe(r)
                target = next(p['targets'][system] for p in products if p['id'] == key)
                self.assertTrue(target['supported'])
                self.assertEqual(target['version'], r['version'])

    def test_matching_version_with_wrong_architecture_is_drift(self):
        b = dict(name='Synth.vst3', id='synth', version='1.0', format='VST3', architectures=['x86_64'])
        product = dict(bundles=[b], architecture='arm64')
        self.assertEqual(audio.status(product, [b])[0]['state'], 'drift')
        self.assertEqual(audio.status(product, [dict(b, architectures=['x86_64', 'arm64'])])[0]['state'], 'ok')

    def test_native_targets_never_inherit_intel_fallback(self):
        for product in audio.read_json(audio.BASE / 'catalog.json')['products']:
            native = product['targets']['aarch64-darwin']
            self.assertEqual(native['architecture'], 'arm64')
            if not native['supported']:
                self.assertEqual(native['bundles'], [])
                self.assertTrue(native['reason'])


if __name__ == '__main__': unittest.main()
