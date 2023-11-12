{ pkgs }:
with pkgs;
let
  util = import ../util.nix { pkgs = pkgs; };
  version = "4.16.0";
  urlVersion = "95345";
  urlInfo = let
  in {
    x86_64-darwin = {
      url =
        "https://desktop.docker.com/mac/main/amd64/${urlVersion}/Docker.dmg";
      sha256 = "T6lekLbDlACUOyY65aobtttbJgQ90BSMTjfTAzp1TTM=";
    };
    aarch64-darwin = {
      url =
        "https://desktop.docker.com/mac/main/arm64/${urlVersion}/Docker.dmg";
      sha256 = "MQGTSjsGKzc6Iv2ZTXQ/pqCPqAVpWDnmtjvC0o689Zo=";
    };
  }.${system} or (throw "Unsupported system: ${system}");
in with util;
installXZCompressedApplication {
  name = "Docker";
  version = version;
  sourceRoot = "Docker.app";
  src = fetchurl urlInfo;
  description = "Docker Desktop";
  homepage = "https://docs.docker.com/desktop/release-notes/";
}
