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
    in let
      myLib =
        import ./lib/lib.nix { inherit darwin intel-packages arm-packages; };
    in let
      base-intel =
        (import ./darwin/bootstrap.nix { hostPlatform = "x86_64-darwin"; });

      base-arm =
        (import ./darwin/bootstrap.nix { hostPlatform = "aarch64-darwin"; });
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

      dotfiles = lib.makeOverridable
        ({ home, withVSCodeSettings, withShell, withDotFiles }:
          { pkgs, ... }: {
            system.activationScripts.postActivation.text =
              myLib.configure-environment {
                inherit home pkgs lib withVSCodeSettings withShell withDotFiles;
              };
          }) {
            home = "/Users/matt";
            withVSCodeSettings =
              (lib.fileContents ./config/vscode/matt/settings.json);
            withShell = "";
            withDotFiles = [ ];
          };
    in base // {
      lib = myLib;
      nixpkgs = nixpkgs;
      base-intel = base-intel;
      base-arm = base-arm;
      dotfiles = dotfiles;
      intel-packages = intel-packages;
      arm-packages = arm-packages;

      darwinConfigurations = {
        x = darwin.lib.darwinSystem {
          modules = [ base-intel intel-packages dotfiles ];
        };
        y = darwin.lib.darwinSystem {
          modules = [ base-arm arm-packages dotfiles ];
        };
        ci-intel = darwin.lib.darwinSystem {
          modules = [ base-intel ci-intel-packages ];
        };
        ci-arm =
          darwin.lib.darwinSystem { modules = [ base-arm ci-arm-packages ]; };
      };
    };
}
