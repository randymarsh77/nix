{ pkgs }:
with pkgs;
let
  util = import ../../util.nix { pkgs = pkgs; };
  version = "2023.1.EAP6";
  urlInfo = let
  in {
    x86_64-darwin = {
      url =
        "https://download.jetbrains.com/resharper/dotUltimate.${version}/JetBrains.dotTrace.CommandLineTools.macos-x64.${version}.Checked.tar.gz";
      sha256 = "sha256-wywcwVdPAggyU2puX+jIlcyX4uvwp4vTjEgDw2e4r7w=";
    };
    aarch64-darwin = {
      url =
        "https://download.jetbrains.com/resharper/dotUltimate.${version}/JetBrains.dotTrace.CommandLineTools.macos-arm64.${version}.Checked.tar.gz";
      sha256 = "sha256-lGPmpnaCEZJ9ts5IfwxLhZ0PefgFS+Y4ybi5ITwRzq4=";
    };
  }.${system} or (throw "Unsupported system: ${system}");
in with util;
installExecutableBundle {
  name = "dottrace";
  version = version;
  src = fetchurl urlInfo;
  description = "Dot Trace";
  homepage = "https://www.jetbrains.com/resharper/nextversion";
}
