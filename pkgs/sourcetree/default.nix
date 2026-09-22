# nix-update-tool.feed: https://product-downloads.atlassian.com/software/sourcetree/Appcast/SparkleAppcastGroup4.xml
{ pkgs }:
let
  util = import ../util.nix { pkgs = pkgs; };
  version = "4.2.17_311";
in
with util;
installApplication {
  name = "Sourcetree";
  version = version;
  sourceRoot = "Sourcetree.app";
  src = pkgs.fetchurl {
    url = "https://product-downloads.atlassian.com/software/sourcetree/ga/Sourcetree_${version}.zip";
    sha256 = "sha256-Dor8pPAfY8Z/5RmCH3+P0O+Pi6TmkOR8I5Fc/S3HZwg=";
  };
  description = "Sourcetree is a free git GUI";
  homepage = "https://www.sourcetreeapp.com";
}
