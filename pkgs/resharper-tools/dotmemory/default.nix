{ pkgs }:
with pkgs;
let
  util = import ../../util.nix { pkgs = pkgs; };
  version = "2025.3.3";
  urlInfo =
    {
      x86_64-darwin = {
        url = "https://download.jetbrains.com/resharper/dotUltimate.${version}/JetBrains.dotMemory.Console.macos-x64.${version}.Checked.tar.gz";
        sha256 = "sha256-eC1z/AD13vdRxqLc9oJX1l4BeK97MbrvcJco8HxBsUw=";
      };
      aarch64-darwin = {
        url = "https://download.jetbrains.com/resharper/dotUltimate.${version}/JetBrains.dotMemory.Console.macos-arm64.${version}.Checked.tar.gz";
        sha256 = "sha256-Gwi8rAUrLn6py17if/zxr+Q0fnrs4NKW0f/aPnz1yjs=";
      };
    }
    .${system} or (throw "Unsupported system: ${system}");
in
with util;
installExecutableBundle {
  name = "dotmemory";
  version = version;
  src = fetchurl urlInfo;
  description = "JetBrains dotMemory console profiler";
  homepage = "https://www.jetbrains.com/dotmemory/";
}
