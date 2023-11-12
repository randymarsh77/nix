{ pkgs }:
let
  util = import ../util.nix { pkgs = pkgs; };
  version = "4.6.3";
in with util;
installApplication {
  name = "Charles";
  version = version;
  sourceRoot = "Charles.app";
  src = pkgs.fetchurl {
    url =
      "https://www.charlesproxy.com/assets/release/${version}/charles-proxy-${version}.dmg";
    sha256 = "wxJeUwX/IZhX/xsSNvfWYS/WANwJhVDDKHqTjHMhemM=";
  };
  description = "Charles Proxy";
  homepage = "https://www.charlesproxy.com/latest-release";
}
