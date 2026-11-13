# The official Blender build.
#
# nixpkgs builds Blender from source, and that build is not in the binary cache for macOS.
# Blender only ships Apple Silicon builds for macOS.
{ pkgs }:
let
  util = import ../util.nix { pkgs = pkgs; };
  version = "5.3.0";
  series = pkgs.lib.versions.majorMinor version;
  file = "Blender${series}/blender-${version}-macos-arm64.dmg";
in
with util;
(installApplication {
  name = "Blender";
  version = version;
  sourceRoot = "Blender.app";
  src = pkgs.fetchurl {
    # download.blender.org can answer scripted downloads with a browser check, so fall back to
    # mirrors from https://www.blender.org/about/website/mirrors/.
    urls = [
      "https://download.blender.org/release/${file}"
      "https://mirror.clarkson.edu/blender/release/${file}"
      "https://mirrors.ocf.berkeley.edu/blender/release/${file}"
    ];
    sha256 = "sha256-LYArVHZnQeYSzq1QsD67yOtk2txx7akyVz0la4p4RyA=";
  };
  description = "Blender";
  homepage = "https://www.blender.org/download/";
}).overrideAttrs
  (old: {
    meta = old.meta // {
      platforms = [ "aarch64-darwin" ];
    };
  })
