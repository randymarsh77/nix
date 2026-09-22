{ pkgs }:
with pkgs;
let
  util = import ../../util.nix { pkgs = pkgs; };
  version = "2026.1.1";
  urlInfo =
    {
      x86_64-darwin = {
        url = "https://download.jetbrains.com/resharper/dotUltimate.${version}/JetBrains.dotTrace.CommandLineTools.macos-x64.${version}.tar.gz";
        sha256 = "sha256-grvdf0qU08uMB3KwEt6WicLPOI0H4AryYjYgGme6iMQ=";
      };
      aarch64-darwin = {
        url = "https://download.jetbrains.com/resharper/dotUltimate.${version}/JetBrains.dotTrace.CommandLineTools.macos-arm64.${version}.tar.gz";
        sha256 = "sha256-4wVQcNGEoYS8T48w42+h7/UClqGhWWTOe5SN4Kb3eYk=";
      };
    }
    .${stdenv.hostPlatform.system} or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
with util;
installExecutableBundle {
  name = "dottrace";
  version = version;
  src = fetchurl urlInfo;
  description = "JetBrains dotTrace command line profiler";
  homepage = "https://www.jetbrains.com/profiler/";
}
