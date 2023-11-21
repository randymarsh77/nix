{
  description = "Useful macOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/master";
    darwin.url = "github:LnL7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, flake-utils, darwin }:
    with nixpkgs;
    let localOverlay = import ./pkgs/default.nix;
    in let
      myLib = import ./lib/lib.nix { };
      legacyPackages = nixpkgs.lib.genAttrs [ "x86_64-darwin" "aarch64-darwin" ]
        (system:
          import nixpkgs {
            inherit system;
            overlays = [ localOverlay ];
            config.allowUnfree = true;
          });
    in let
      base = flake-utils.lib.eachDefaultSystem (system: {
        packages = legacyPackages;
        constants = rec {
          default-packages =
            (import ./util/util.nix { }).create-default-packages {
              nixpkgs = legacyPackages.${system};
            };
        };
      });
    in let
      intel-packages = { pkgs, ... }: {
        # azure-cli is broken on Intel; filter it out.
        environment.systemPackages = (builtins.filter (x: x != pkgs.azure-cli)
          base.constants.x86_64-darwin.default-packages);
      };
      arm-packages = { pkgs, ... }: {
        environment.systemPackages =
          base.constants.aarch64-darwin.default-packages;
      };
      ci-intel-packages = { pkgs, ... }: {
        # azure-cli is broken on Intel; filter it out.
        # mysql-workbench-dist can't upload to Cachix; filter it out.
        environment.systemPackages = (builtins.filter (x:
          x != pkgs.azure-cli
          && (x != legacyPackages.x86_64-darwin.mysql-workbench-dist))
          base.constants.x86_64-darwin.default-packages);
      };
      ci-arm-packages = { pkgs, ... }: {
        # mysql-workbench-dist can't upload to Cachix; filter it out.
        environment.systemPackages = (builtins.filter
          (x: x != legacyPackages.aarch64-darwin.mysql-workbench-dist)
          base.constants.aarch64-darwin.default-packages);
      };

      dotfiles = { home }:
        { pkgs, ... }: {
          system.activationScripts.postActivation.text =
            myLib.configure-environment {
              inherit home pkgs lib;
              withVSCodeSettings =
                (lib.fileContents ./config/vscode/matt/settings.json);
            };
        };
    in base // {
      lib = myLib;

      darwinConfigurations = {
        x = darwin.lib.darwinSystem {
          modules = [
            (import ./darwin/bootstrap.nix { hostPlatform = "x86_64-darwin"; })
            intel-packages
            (dotfiles { home = "/Users/matt"; })
          ];
        };
        ci-intel = darwin.lib.darwinSystem {
          modules = [
            (import ./darwin/bootstrap.nix { hostPlatform = "x86_64-darwin"; })
            ci-intel-packages
          ];
        };
        ci-arm = darwin.lib.darwinSystem {
          modules = [
            (import ./darwin/bootstrap.nix { hostPlatform = "aarch64-darwin"; })
            ci-arm-packages
          ];
        };
      };
    };
}
