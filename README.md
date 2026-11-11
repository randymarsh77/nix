# My Nix configs

Packages and utility functions for use with nix-darwin.

To configure another Mac, download or clone this repository,
open Terminal in its directory, and run:

```sh
./scripts/install-nix  # Only needed if Nix is not installed
./scripts/build        # Build without changing the system
./scripts/apply        # Build, then activate with sudo
```

The scripts run with macOS's built-in Bash; no direnv or task runner is required.
They select `y` on Apple Silicon (including a Rosetta terminal) and `x` on Intel,
and read the existing `nixbld` group ID from Directory Services and the name of
the user running them. Both are applied as a local module override, leaving the
flake's shared defaults unchanged.
`apply` records a system generation and activates the exact configuration it built.
Once applied, `sudo` accepts Touch ID, so later runs of `apply` do not ask for a password.
Dotfiles and apps are installed for the detected user; VS Code settings from
`config/vscode/<user>/settings.json` are merged in when that file exists. Likewise,
`config/git/<user>/config` is installed as `~/.config/git/config`, which sets the
Git name and email; `~/.gitconfig` is left alone for machine-local overrides. Built
directly from the flake, both configurations install dotfiles for `/Users/matt`.

If direnv is installed, run `direnv allow` to expose `build` and `apply` as commands
while in this checkout. Entering the directory does not build or activate anything.

The base configuration installs the official .NET SDK into `/usr/local/share/dotnet`
and adds that directory to the system shell PATH.

VS Code extension IDs are configured in `config/vscode/extensions/default.nix`.
System activation asks the VS Code CLI to install missing extensions into the
user profile, so VS Code retains ownership of Marketplace binaries and updates.
