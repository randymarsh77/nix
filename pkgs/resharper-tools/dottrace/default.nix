{ pkgs }:
with pkgs;
let
  util = import ../../util.nix { pkgs = pkgs; };
  version = "2025.3.3";
  urlInfo =
    {
      x86_64-darwin = {
        url = "https://download.jetbrains.com/resharper/dotUltimate.${version}/JetBrains.dotTrace.CommandLineTools.macos-x64.${version}.tar.gz";
        sha256 = "sha256-FaS37CCs61nrFQcNmvSPqooafdH67En6+PEFkCMDvyM=";
      };
      aarch64-darwin = {
        url = "https://download.jetbrains.com/resharper/dotUltimate.${version}/JetBrains.dotTrace.CommandLineTools.macos-arm64.${version}.tar.gz";
        sha256 = "sha256-JWxP89L8syqvbL98HPKpmndSGmzKWSEZhuKnbwZVXFY=";
      };
    }
    .${system} or (throw "Unsupported system: ${system}");
in
with util;
installExecutableBundle {
  name = "dottrace";
  version = version;
  src = fetchurl urlInfo;
  description = "JetBrains dotTrace command line profiler";
  homepage = "https://www.jetbrains.com/profiler/";
}
