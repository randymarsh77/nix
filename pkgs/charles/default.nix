{ pkgs }:
let
  util = import ../util.nix { pkgs = pkgs; };
  version = "5.1";
in with util;
installApplication {
  name = "Charles";
  version = version;
  sourceRoot = "Charles.app";
  src = pkgs.fetchurl {
    url =
      "https://www.charlesproxy.com/assets/release/${version}/charles-proxy-${version}.dmg";
    sha256 = "sha256-BTBzO8pFSGV9ixcmQz+btaDmmd4mx12R4Egx6ciUjbE=";
  };
  description = "Charles Proxy";
  homepage = "https://www.charlesproxy.com/latest-release";
}
