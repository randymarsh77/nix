{ pkgs }:
with pkgs;
let
  util = import ../util.nix { pkgs = pkgs; };
  version = "3.12.2";
  urlInfo = let
  in {
    x86_64-darwin = {
      url =
        "https://download.sqlitebrowser.org/DB.Browser.for.SQLite-intel-${version}.dmg";
      sha256 = "/D7s2lI4BEWa+KMw9i2OEqigeRULRbtZSz8HMpC6wXE=";
    };
    aarch64-darwin = {
      url =
        "https://download.sqlitebrowser.org/DB.Browser.for.SQLite-arm64-${version}.dmg";
      sha256 = "DCB25EecudtchRI8/pdQZB+SVmaU/59smZBjIaLEJOg=";
    };
  }.${system} or (throw "Unsupported system: ${system}");
in with util;
installApplication {
  name = "DB Browser for SQLite";
  version = version;
  sourceRoot = "DB Browser for SQLite.app";
  src = fetchurl urlInfo;
  description = "DB Browser for SQLite";
  homepage = "https://sqlitebrowser.org";
}
