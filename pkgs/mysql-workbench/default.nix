{ pkgs }:
with pkgs;
let
  util = import ../util.nix { pkgs = pkgs; };
  version = "8.0.47";
  urlInfo = let
  in {
    x86_64-darwin = {
      url =
        "https://dev.mysql.com/get/Downloads/MySQLGUITools/mysql-workbench-community-${version}-macos-x86_64.dmg";
      sha256 = "sha256-n7gkRrjImlMm+cSyq1mrasdrOJcT8fE1U3Q/NJUmOag=";
    };
    aarch64-darwin = {
      url =
        "https://dev.mysql.com/get/Downloads/MySQLGUITools/mysql-workbench-community-${version}-macos-arm64.dmg";
      sha256 = "sha256-kLF3A0s+LGS4IvRJIMsRmW7BMj9MSeL6AiR0gQP7SEQ=";
    };
  }.${stdenv.hostPlatform.system} or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in with util;
installApplication {
  name = "MySQLWorkbench";
  version = "${version}-dist";
  sourceRoot = "MySQLWorkbench.app";
  src = fetchurl urlInfo;
  description = "MySQL Workbench";
  homepage = "https://dev.mysql.com/downloads/workbench/";
}
