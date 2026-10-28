# Audio plugins (opt-in flake)

A separate macOS flake for the studio plugin collection inventoried on 2026-10-27.
Nothing imports this flake from the repository's root flake, package defaults or
Darwin activation scripts. It exports the explicitly named `audio-plugins`
package/app for Intel and Apple Silicon Macs; it has no default package or app.

Nix selects the catalog and installer recipes by `pkgs.stdenv.hostPlatform.system`:
`aarch64-darwin` gets native Apple Silicon targets, and `x86_64-darwin` gets the
observed Intel versions. Universal vendor installers are used where available.
There is no implicit Intel/Rosetta fallback for an unavailable native target.

The baseline contains 137 AU, VST2, VST3, AAX and RTAS bundles grouped into 27
commercial product/install groups, plus one AUv3Filter development sample.
Bundle IDs, formats and exact observed version strings are retained. The catalog
also records Ableton Live Suite 10.1.43 and 11.3.20 and the installed vendor
managers. Ableton installation, Packs, User Library, cloud samples and presets
are outside this implementation.

## Run without changing the computer

From the repository root (the explicit `path:` also works before files are committed):

```sh
nix run path:./audio#audio-plugins -- list
nix run path:./audio#audio-plugins -- status
nix run path:./audio#audio-plugins -- status --formats AU VST2 VST3
nix run path:./audio#audio-plugins -- plan
nix run path:./audio#audio-plugins -- guide serum
nix run path:./audio#audio-plugins -- inventory > /tmp/audio-inventory.json
```

`status` returns 1 for missing/differing/duplicate bundles or unavailable architecture targets, 0 for a match, and 2
for an operational error. `plan` returns 0 and describes installation and
activation work. Neither checks entitlement, activation, runtime compatibility
or whether a DAW can actually load the plugin. System and user plugin copies
are compared together; a duplicate is reported even when versions match.

Inventory scans the system/user Audio Plug-Ins trees, Avid and legacy Digidesign
locations, and AUv3 extensions under `/Applications` and `~/Applications`.
It reads bundle metadata, not license files. Custom plugin paths on external
drives can be scanned with repeatable `inventory --root /path` arguments;
`--app-root /path` overrides the AUv3 app roots. The checked-in baseline is not
a claim that every possible external or custom folder was searched.

## Consume from another flake

After these files are committed and available at the remote:

```nix
inputs.audio.url = "github:randymarsh77/nix?dir=audio";
# Optionally use your consumer's nixpkgs pin:
# inputs.audio.inputs.nixpkgs.follows = "nixpkgs";

# In an explicitly selected nix-darwin configuration only:
environment.systemPackages = [
  inputs.audio.packages.${pkgs.stdenv.hostPlatform.system}.audio-plugins
];
```

This installs the management command only. Plugin installers run solely on an
explicit command, never during evaluation, builds, or system activation.

## Install a pinned vendor distribution

```sh
# Review the intended operation (does not download or install):
nix run path:./audio#audio-plugins -- install archetype-gojira
# Download to the user cache, check SHA-256, signer and Gatekeeper:
nix run path:./audio#audio-plugins -- fetch archetype-gojira
# Close Ableton and other audio hosts, then explicitly install:
nix run path:./audio#audio-plugins -- install archetype-gojira --apply
```

For a flat package, the official `.pkg` is passed to macOS `installer` through `sudo`; the
vendor controls installed formats, support files and standalone applications.
The command does not customize package choices or remove unrequested formats.
The selected architecture determines the expected native formats; a universal
vendor installer may additionally install Intel-only formats.
DMG images are mounted read-only, and ZIP archives are extracted temporarily;
both must identify an exact `.pkg` or signed installer `.app` member.
Some iZotope releases use interactive installer apps. These open with `open -W`
and require completing the vendor wizard; the command then checks the resulting
plugin bundles. Their signatures and Gatekeeper assessments are verified before
launch, and the image remains mounted until the installer app exits. No installer payload is executed
while downloading, pinning, or building the Nix package.

Installers live in `~/Library/Caches/nix-audio`, outside Git and the Nix store.
Every fetch/import checks the artifact SHA-256. Installation checks the signing
Team ID (or a pinned legacy signing certificate) and Gatekeeper. Changed
artifacts, mismatched signers and Gatekeeper rejection fail closed. Vendor
websites can retire an old download; keep permitted private archival copies if
long-term recall is required. `fetch/install --file /path/to/installer` can use
an archived or account-only download with the exact pinned hash.

Matching installed bundles cause installation to be skipped. After an install,
all targeted bundles for that product are checked again; incomplete/mismatched
results return exit code 3. Installer execution is not transactional, and a Nix
rollback does not roll back vendor installation. Activation is a separate step.

## Account-only and unpinned installers

`guide PRODUCT --open` opens the vendor source page. Install/sign into the
appropriate official manager when required: Native Access, iZotope Product
Portal, iLok License Manager, or Splice. The catalog includes their source pages
and observed versions; manager installation and GUI login are currently guided
steps, not automated provisioning. The presence of Splice does not establish
that Serum is rented through it.

For a product without a recipe, `install` returns 2 and explains the vendor
route. It never substitutes a newer version. After downloading the exact vendor
installer, inspect its signature, then create a recipe:

```sh
/usr/sbin/pkgutil --check-signature /path/to/official-installer.pkg
nix run path:./audio#audio-plugins -- lock serum \
  --file /path/to/official-installer.pkg \
  --version 1.334 --team-id VENDORTEAM \
  --output ./audio/installers.json
```

Replace `VENDORTEAM` with the actual ten-character vendor Team ID. For DMG/ZIP
use `--member 'relative/path/to/Installer.pkg'` (or an installer `.app`) and the enclosing archive as
`--file`. For a legacy certificate without a Team ID, use
`--certificate-sha256 HEX` instead. The lock command verifies the signature and
Gatekeeper before writing a recipe under the current Nix system. The file has
the shape `{ "product-id": { "aarch64-darwin": { ... }, "x86_64-darwin": { ... } }`. Its hash is trust-on-first-use from your authenticated
vendor download; product version/edition is asserted by you, not inferred from
the filename. Installed bundle versions are subsequently verified by `install`.

An optional `--url` must be a public HTTPS vendor distribution URL. Personalized,
tokenized, account-download URLs and credentials must not be committed. Without
one, use `--file` on each computer (or its existing verified cache). Keep license
keys out of the installer lock file. For an external writable lock file, pass
`--installers /absolute/path/installers.json` **before** the subcommand.

Upgrading is deliberate: update the relevant `targets.SYSTEM.version` and expected bundle version
strings in `catalog.json`, verify the correct edition and compatibility, then
pin its installer. Do not assume a native AU/VST3 target can replace a project’s VST2 dependency, or
replace an original Neural DSP plugin with its X edition: old sessions can refer
to their original plugin identifiers. Native Access and other vendor managers
may not offer every historical version; their updates can produce reported drift.

## Licenses and 1Password

No keys or activation databases were read, exported or checked into this repo.
iLok, machine-bound licenses and account activations use the vendor UI; they
cannot generally be restored by copying a file. `guide` describes each product's
activation route. The app does not consume license seats automatically.

For a product whose vendor explicitly supports placing a portable license file,
create a runtime JSON mapping outside the repository, for example
`~/.config/audio-plugins/licenses.json`:

```json
{
  "product-id": {
    "reference": "op://Music/Plugin/license-file",
    "destination": "~/vendor-documented/location/license.dat"
  }
}
```

Both the product ID and destination are placeholders: use an actual catalog ID
and the vendor-documented destination. No destination is assumed for the current
products. Create its parent directory first. The installed 1Password CLI (`op`)
must be available on PATH and authenticated in your interactive user session.

```sh
nix run path:./audio#audio-plugins -- license-install PRODUCT \
  --config ~/.config/audio-plugins/licenses.json
# Add --apply only after reviewing the destination and vendor requirements.
```

The command retrieves the file at runtime, preserves its bytes, writes it
atomically with mode 0600, and does not print secret output. An existing file at
the chosen destination is replaced. Failed retrieval leaves it unchanged. This
is a license-file deployment mechanism, not an activation bypass or a generic
serial-to-license converter. The config contains references, never secret values;
do not interpolate `op read` into Nix expressions or derivations.

## Compatibility and validation

The top-level product bundles preserve the original inventory. Each product has
separate `targets.aarch64-darwin` and `targets.x86_64-darwin` records; installer
recipes are selected using the same Nix system. Native targets can use a newer
compatible release without rewriting the original inventory. Intel targets omit
obsolete 32-bit-only bundles. For example, the observed Melodyne 4 VST2 bundle
is 32-bit-only and remains recorded but is not a modern macOS installation target.

The five Neural DSP native targets were checked by expanding their official
packages and inspecting the actual arm64 binary slices. Existing universal
FM8, Massive, Kontakt 7, Serum and Captain plugins supply native target metadata;
their account-only installers still need pinning. Captain Beat is not native in
this baseline, and Captain's native target covers the other four plugins' AU
formats only. `status` also checks actual installed binary architecture.

The native iZotope targets use Nectar 3 Plus, Neutron 3 Standard, and Ozone 9
Standard installers. The baseline bundle metadata does not prove the account's
licensed edition: review the edition shown by `plan`/`install` and your license.
These installers are cryptographically verified, and native support is based on
[iZotope's compatibility table](https://support.izotope.com/hc/en-us/articles/7445672367261-Compatibility-of-iZotope-Products-on-macOS).
Their proprietary payloads cannot be inspected like flat packages: expected
bundle IDs/names are carried forward from the inventory and versions from the
vendor release, with mandatory post-install checks. Neither plugin loading nor
activation has been tested. The installer wizard may also install bundled
products (such as RX Breath Control); those remain independently inventoried.

The Neural DSP original-product native update approach is also documented in
[Neural DSP's Apple Silicon announcement](https://neuraldsp.com/news/apple-native-silicon-updates-for-archetype-plini-and-archetype-gojira).
Public distributions were taken from the official
[Neural DSP downloads](https://neuraldsp.com/downloads) and
[iZotope legacy downloads](https://www.izotope.com/pages/legacy-products) pages.
NI account acquisition is documented under
[previous-version downloads](https://support.native-instruments.com/support/solutions/articles/69000884549-how-to-download-previous-versions-of-native-instruments-software-from-your-account).

A product marked unsupported has no configured native target; its reason
distinguishes legacy-only products from acquisition or verification still needed.
No Rosetta installation or silent major-version replacement is performed.
Architecture selection does not establish OS compatibility; check the vendor and
test your actual Ableton configuration. A signed, accepted legacy
installer does not establish that the plugin will run on a newer macOS release.

```sh
python3 -m unittest discover -s audio/tests -v
nix flake check path:./audio
```

Both system outputs can be evaluated with `nix flake check path:./audio --all-systems --no-build`.
The lock initially reuses the repository's existing nixpkgs revision.

Tests cover metadata discovery, AUv3 discovery, duplicate/version drift,
checksum rejection and cache recovery, archive traversal, signer/Gatekeeper
failure, non-mutating install previews, and runtime license-file handling.
Actual vendor installation/activation is deliberately not part of these tests.

## Catalog coverage

“Pinned” means the official artifact hash, signer and Gatekeeper assessment were
verified. Account/download steps still require the product-specific guide.
“Not configured” does not always mean no native version exists; the per-product
`plan` reason identifies the remaining acquisition, verification or upgrade step.

| Product / group | Intel target | Apple Silicon target |
| --- | --- | --- |
| Absynth 5 | 5.3.1 (R1628) — vendor acquisition | Not configured; see plan |
| Archetype Gojira | 1.0.0 — pinned | 1.0.1 — pinned |
| Archetype Tim Henson | 1.0.0 — pinned | 1.0.1 — pinned |
| AUv3Filter sample | 1.0 — vendor acquisition | Not configured; see plan |
| Captain Plugins 5 | 5.1.3 — vendor acquisition | 5.1.3 — vendor acquisition |
| Darkglass Ultra | 3.0.0 — pinned | 3.0.1 — pinned |
| FM8 | 1.4.6+3 — vendor acquisition | 1.4.6+3 — vendor acquisition |
| Fortin Cali Suite | 1.0.0 — pinned | 2.0.1 — pinned |
| Fortin Nameless Suite | 3.0.1 — pinned | 3.0.2 — pinned |
| Guitar Rig 5 | 5.2.2 (R8) — vendor acquisition | Not configured; see plan |
| Kontakt 5 | 5.8.1 (R43) — vendor acquisition | Not configured; see plan |
| Kontakt 6 | 6.6.1 (R139) — vendor acquisition | Not configured; see plan |
| Kontakt 7 | 7.4.2 — vendor acquisition | 7.4.2 — vendor acquisition |
| Massive | 1.5.12+31 — vendor acquisition | 1.5.12+31 — vendor acquisition |
| Melodyne 4 | 4.2.4 — vendor acquisition | Not configured; see plan |
| MIDI Bass | 1.2.1 — vendor acquisition | Not configured; see plan |
| MIDI Guitar 2 | 2.2.1 — vendor acquisition | Not configured; see plan |
| Nectar 2 | 2.0.4 — pinned | Not configured; see plan |
| Nectar 3 | 3.6.0 — vendor acquisition | 3.9.0 — pinned |
| Neutron 3 | 3.7.0 — vendor acquisition | 3.10.0 — pinned |
| Ozone 5 | 5.0.5 — vendor acquisition | Not configured; see plan |
| Ozone 9 | 9.1.0 — vendor acquisition | 9.13.0 — pinned |
| Reaktor 5 | 5.9.4 (R1512) — vendor acquisition | Not configured; see plan |
| Reaktor 6 | 6.3.1 (R6) — vendor acquisition | Not configured; see plan |
| Relay | 1.1.0 — vendor acquisition | Not configured; see plan |
| RX 8 Breath Control | 8.1.0 — vendor acquisition | Not configured; see plan |
| Satellite | 2.2.1 — vendor acquisition | Not configured; see plan |
| Serum | 1.334 — vendor acquisition | 1.334 — vendor acquisition |
