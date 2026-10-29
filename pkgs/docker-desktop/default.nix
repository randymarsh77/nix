{ pkgs }:
with pkgs;
let
  util = import ../util.nix { pkgs = pkgs; };
  version = "4.97.0";
  urlVersion = "244584";
  urlInfo =
    let
    in
    {
      x86_64-darwin = {
        url = "https://desktop.docker.com/mac/main/amd64/${urlVersion}/Docker.dmg";
        sha256 = "sha256-mNoagtrHNLpqFMPgN59WVc4L1SoEz4u0f05GQskU9pU=";
      };
      aarch64-darwin = {
        url = "https://desktop.docker.com/mac/main/arm64/${urlVersion}/Docker.dmg";
        sha256 = "sha256-lOTM7EoDW33N9nz/8FINS0buhzrgSxVavA0iszPMkK0=";
      };
    }
    .${stdenv.hostPlatform.system} or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
with util;
installXZCompressedApplication {
  name = "Docker";
  version = version;
  sourceRoot = "Docker.app";
  src = fetchurl urlInfo;
  description = "Docker Desktop";
  homepage = "https://docs.docker.com/desktop/release-notes/";
}
