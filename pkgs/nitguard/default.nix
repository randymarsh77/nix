{ pkgs }:
let
  util = import ../util.nix { pkgs = pkgs; };
  version = "1.6.0";
in with util;
installApplication {
  name = "NitGuard";
  version = version;
  sourceRoot = "NitGuard.app";
  src = pkgs.fetchurl {
    url = "https://www.nitguard.com/install/NitGuard-v${version}.dmg";
    sha256 = "njy/zcBprh+0iAItGKcEecsStX6YPgRrcmK36uVDAi8=";
  };
  description = "NitGuard";
  homepage = "https://nitguard.com";
}
