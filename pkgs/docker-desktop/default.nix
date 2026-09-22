{ pkgs }:
with pkgs;
let
  util = import ../util.nix { pkgs = pkgs; };
  version = "4.73.0";
  urlVersion = "226246";
  urlInfo = let
  in {
    x86_64-darwin = {
      url =
        "https://desktop.docker.com/mac/main/amd64/${urlVersion}/Docker.dmg";
      sha256 = "sha256-qIpjtMdNXoXJ1B7JtAZUcriBLA49+2PjH92j07Emios=";
    };
    aarch64-darwin = {
      url =
        "https://desktop.docker.com/mac/main/arm64/${urlVersion}/Docker.dmg";
      sha256 = "sha256-Xwi14+fjPMp8NkpYWxW86klHFZYGRTCVqKCbzA/UQAU=";
    };
  }.${stdenv.hostPlatform.system} or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in with util;
installXZCompressedApplication {
  name = "Docker";
  version = version;
  sourceRoot = "Docker.app";
  src = fetchurl urlInfo;
  description = "Docker Desktop";
  homepage = "https://docs.docker.com/desktop/release-notes/";
}
