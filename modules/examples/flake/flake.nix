{
  description = "Basic macOS configuration";

  # Replace the url with a remote path: "github:randymarsh77/nix/master";
  inputs = { x.url = "git+file:../../.."; };

  outputs = inputs@{ self, x }: {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#my-system
    # Replace "my-system" with your system name: $(scutil --get LocalHostName)

    darwinConfigurations = {
      my-system = x.lib.make-darwin-system {
        hostPlatform = "x86_64-darwin";
        modules = [
          (x.dotfiles.override {
            home = "/Users/example";
            withVSCodeSettings =
              (x.nixpkgs.lib.fileContents ./config/vscode/settings.json);
          })
        ];
      };
    };
  };
}
