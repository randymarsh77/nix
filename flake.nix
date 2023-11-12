{
  description = "Useful macOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/master";
    localpkgs.url = "git+file:.?dir=pkgs";
    localpkgs.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, flake-utils, localpkgs }:
    let
      legacyPackages = nixpkgs.lib.genAttrs [ "x86_64-darwin" "aarch64-darwin" ]
        (system:
          import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          });
    in flake-utils.lib.eachDefaultSystem (system: {
      packages = localpkgs.packages.${system};
      constants = rec {
        default-packages =
          (import ./util/util.nix { }).create-default-packages {
            nixpkgs = legacyPackages.${system};
            pkgs = localpkgs.packages.${system};
          };
      };
    }) // {
      lib = import ./lib/lib.nix { };
    };
}
