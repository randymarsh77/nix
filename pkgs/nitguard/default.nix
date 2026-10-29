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
    # Preserve the original published installer: the vendor endpoint now returns
    # 503 with a multi-hour Retry-After. Keep its existing content hash below.
    url = "https://github.com/randymarsh77/nix/releases/download/cache-bootstrap/NitGuard-v${version}.dmg";
    sha256 = "njy/zcBprh+0iAItGKcEecsStX6YPgRrcmK36uVDAi8=";
  };
  description = "NitGuard";
  homepage = "https://nitguard.com";
}
