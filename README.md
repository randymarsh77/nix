# My Nix configs

Packages and utility functions for use with nix-darwin.

The base configuration installs the official .NET SDK into `/usr/local/share/dotnet`
and adds that directory to the system shell PATH.

VS Code extension IDs are configured in `config/vscode/extensions/default.nix`.
System activation asks the VS Code CLI to install missing extensions into the
user profile, so VS Code retains ownership of Marketplace binaries and updates.
