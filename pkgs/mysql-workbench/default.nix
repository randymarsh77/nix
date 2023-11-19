{ pkgs }:
with pkgs;
let
  util = import ../util.nix { pkgs = pkgs; };
  version = "8.0.34";
  urlInfo = let
  in {
    x86_64-darwin = {
      url =
        "https://dev.mysql.com/get/Downloads/MySQLGUITools/mysql-workbench-community-${version}-macos-x86_64.dmg";
      sha256 = "n7ploG20xn41MBS0nEHXzQ6RXdZYTfQ9bLCZ84z4QeI=";
    };
    aarch64-darwin = {
      url =
        "https://dev.mysql.com/get/Downloads/MySQLGUITools/mysql-workbench-community-${version}-macos-arm64.dmg";
      sha256 = "rqZ8OTVNdsOPLprKQ5Db5PdezD8SEQ/1mL8vxG9Iv4w=";
    };
  }.${system} or (throw "Unsupported system: ${system}");
in with util;
installApplication {
  name = "MySQLWorkbench";
  version = "${version}-dist";
  sourceRoot = "MySQLWorkbench.app";
  src = fetchurl urlInfo;
  description = "MySQL Workbench";
  homepage = "https://dev.mysql.com/downloads/workbench/";
}
