{
  description = "Useful macOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/master";
    darwin.url = "github:LnL7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    localpkgs.url = "git+file:.?dir=pkgs";
    localpkgs.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, flake-utils, darwin, localpkgs }:
    with nixpkgs;
    let
      myLib = import ./lib/lib.nix { };
      legacyPackages = nixpkgs.lib.genAttrs [ "x86_64-darwin" "aarch64-darwin" ]
        (system:
          import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          });
    in let
      base = flake-utils.lib.eachDefaultSystem (system: {
        packages = localpkgs;
        constants = rec {
          default-packages =
            (import ./util/util.nix { }).create-default-packages {
              nixpkgs = legacyPackages.${system};
              pkgs = localpkgs.packages.${system};
            };
        };
      });
    in let
      x86-packages = { pkgs, ... }: {
        # azure-cli is broken on Intel; filter it out.
        environment.systemPackages = (builtins.filter (x: x != pkgs.azure-cli)
          base.constants.x86_64-darwin.default-packages) ++ [ pkgs.cachix ];
      };
      arm-packages = { pkgs, ... }: {
        environment.systemPackages =
          base.constants.aarch64-darwin.default-packages ++ [ pkgs.cachix ];
      };
      ci-x86-packages = { pkgs, ... }: {
        # azure-cli is broken on Intel; filter it out.
        # mysql-workbench-dist can't upload to Cachix; filter it out.
        environment.systemPackages = (builtins.filter (x:
          x != pkgs.azure-cli && x
          != localpkgs.packages.x86_64-darwin.mysql-workbench-dist)
          base.constants.x86_64-darwin.default-packages) ++ [ pkgs.cachix ];
      };
      ci-arm-packages = { pkgs, ... }: {
        # mysql-workbench-dist can't upload to Cachix; filter it out.
        environment.systemPackages = (builtins.filter
          (x: x != localpkgs.packages.aarch64-darwin.mysql-workbench-dist)
          base.constants.aarch64-darwin.default-packages) ++ [ pkgs.cachix ];
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
            x86-packages
            (dotfiles { home = "/Users/matt"; })
          ];
        };
        ci-x86 = darwin.lib.darwinSystem {
          modules = [
            (import ./darwin/bootstrap.nix { hostPlatform = "x86_64-darwin"; })
            ci-x86-packages
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
