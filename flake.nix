{
  description = "X";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/master";
    darwin.url = "github:LnL7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    base.url = "github:randymarsh77/nix/master";
    base.inputs.nixpkgs.follows = "nixpkgs";

    localpkgs.url = "github:randymarsh77/nix/master?dir=pkgs";
    base.inputs.localpkgs.follows = "localpkgs";
  };

  outputs = inputs@{ self, darwin, nixpkgs, base, localpkgs }:
    with nixpkgs;
    with lib;
    let
      x86-packages = { pkgs, ... }: {
        # azure-cli is broken on Intel; filter it out.
        # mysql-workbench-dist can't upload to Cachix; filter it out.
        environment.systemPackages = (builtins.filter (x:
          x != pkgs.azure-cli && x
          != localpkgs.packages.x86_64-darwin.mysql-workbench-dist)
          base.constants.x86_64-darwin.default-packages) ++ [ pkgs.cachix ];
      };
      arm-packages = { pkgs, ... }: {
        environment.systemPackages =
          base.constants.aarch64-darwin.default-packages ++ [ pkgs.cachix ];
      };
      dotfiles = { home }:
        { pkgs, ... }: {
          system.activationScripts.postActivation.text =
            base.lib.configure-environment {
              inherit home pkgs lib;
              withVSCodeSettings =
                (lib.fileContents ./config/vscode/settings.json);
            };
        };
    in {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#x
      darwinConfigurations = {
        x = darwin.lib.darwinSystem {
          modules = [
            (import ./darwin/bootstrap.nix { hostPlatform = "x86_64-darwin"; })
            x86-packages
            (dotfiles { home = "/Users/matt"; })
          ];
        };
        ci-x86 = darwin.lib.darwinSystem {
          modules = [
            (import ./darwin/bootstrap.nix { hostPlatform = "x86_64-darwin"; })
            x86-packages
          ];
        };
        ci-arm = darwin.lib.darwinSystem {
          modules = [
            (import ./darwin/bootstrap.nix { hostPlatform = "aarch64-darwin"; })
            arm-packages
          ];
        };
      };

      # Expose the package set, including overlays, for convenience.
      # darwinPackages = self.darwinConfigurations.${machine}.pkgs;
    };
}
