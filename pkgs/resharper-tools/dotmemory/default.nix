{ pkgs }:
with pkgs;
let
  util = import ../../util.nix { pkgs = pkgs; };
  version = "2023.1.EAP6";
  urlInfo = let
  in {
    x86_64-darwin = {
      url =
        "https://download.jetbrains.com/resharper/dotUltimate.${version}/JetBrains.dotMemory.Console.macos-x64.${version}.Checked.tar.gz";
      sha256 = "sha256-piHNbijasjjsqOClSOkWx6A6Kx739YE4viw9aMSQIRM=";
    };
    aarch64-darwin = {
      url =
        "https://download.jetbrains.com/resharper/dotUltimate.${version}/JetBrains.dotMemory.Console.macos-arm64.${version}.Checked.tar.gz";
      sha256 = "sha256-DDy73EHPXkSyAC2LWZn2efjhTh2bSBRuxG8mfM+SmQk=";
    };
  }.${system} or (throw "Unsupported system: ${system}");
in with util;
installExecutableBundle {
  name = "dotmemory";
  version = version;
  src = fetchurl urlInfo;
  description = "Dot Memory";
  homepage = "https://www.jetbrains.com/resharper/nextversion";
}
