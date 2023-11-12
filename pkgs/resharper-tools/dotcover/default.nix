{ pkgs }:
with pkgs;
let
  util = import ../../util.nix { pkgs = pkgs; };
  version = "2023.1.EAP6";
  urlInfo = let
  in {
    x86_64-darwin = {
      url =
        "https://download.jetbrains.com/resharper/dotUltimate.${version}/JetBrains.dotCover.CommandLineTools.macos-x64.${version}.Checked.tar.gz";
      sha256 = "sha256-yspNLlxZOhxTK7tE1DinbwkeFvLOeRZiOP0tQWDm3xs=";
    };
    aarch64-darwin = {
      url =
        "https://download.jetbrains.com/resharper/dotUltimate.${version}/JetBrains.dotCover.CommandLineTools.macos-arm64.${version}.Checked.tar.gz";
      sha256 = "sha256-Rldosi1mOxo0pC5hV6+pLcz8GVUsPFnPflEtfQXvTEY=";
    };
  }.${system} or (throw "Unsupported system: ${system}");
in with util;
installExecutableBundle {
  name = "dotcover";
  version = version;
  src = fetchurl urlInfo;
  description = "Dot Cover";
  homepage = "https://www.jetbrains.com/resharper/nextversion";
}
