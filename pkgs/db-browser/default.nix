{ pkgs }:
with pkgs;
let
  util = import ../util.nix { pkgs = pkgs; };
  version = "3.13.1";
  urlInfo = {
    url = "https://github.com/sqlitebrowser/sqlitebrowser/releases/download/v${version}/DB.Browser.for.SQLite-v${version}.dmg";
    sha256 = "sha256-pkHPv8ws5gnwfeRKNRNNq1NIXswY5tmvope1FNdL114==";
  };
in
with util;
installApplication {
  name = "DB Browser for SQLite";
  version = version;
  sourceRoot = "DB Browser for SQLite.app";
  src = fetchurl urlInfo;
  description = "DB Browser for SQLite";
  homepage = "https://sqlitebrowser.org";
}
