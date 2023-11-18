{ pkgs }:
with pkgs;
let
  util = import ../util.nix { pkgs = pkgs; };
  version = "3.12.2";
  urlInfo = let
  in {
    x86_64-darwin = {
      url =
        "https://download.sqlitebrowser.org/DB.Browser.for.SQLite-${version}.dmg";
      sha256 = "VG1XtsiMK+dRd1nAFsC/AxPfzBSt/LQ5Z/PF0kZX82Y=";
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
