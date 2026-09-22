{ pkgs }:
with pkgs;
let
  util = import ../../util.nix { pkgs = pkgs; };
  version = "2026.1.1";
  urlInfo =
    {
      x86_64-darwin = {
        url = "https://download.jetbrains.com/resharper/dotUltimate.${version}/JetBrains.dotMemory.Console.macos-x64.${version}.Checked.tar.gz";
        sha256 = "sha256-YlJpF+l1TzKurxJLogjVdHStfOxJ9NEiY30e7t+Sbmw=";
      };
      aarch64-darwin = {
        url = "https://download.jetbrains.com/resharper/dotUltimate.${version}/JetBrains.dotMemory.Console.macos-arm64.${version}.Checked.tar.gz";
        sha256 = "sha256-LbqPQ9aRQFZSZp7D0gGmXdo/pGNLNmvbAsm6jFyA57c=";
      };
    }
    .${stdenv.hostPlatform.system} or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
with util;
installExecutableBundle {
  name = "dotmemory";
  version = version;
  src = fetchurl urlInfo;
  description = "JetBrains dotMemory console profiler";
  homepage = "https://www.jetbrains.com/dotmemory/";
}
