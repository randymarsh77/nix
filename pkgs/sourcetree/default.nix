{ pkgs }:
let
  util = import ../util.nix { pkgs = pkgs; };
  version = "4.2.11_271";
in with util;
installApplication {
  name = "Sourcetree";
  version =
    version; # Update Feed: https://product-downloads.atlassian.com/software/sourcetree/Appcast/SparkleAppcastGroup4.xml
  sourceRoot = "Sourcetree.app";
  src = pkgs.fetchurl {
    url =
      "https://product-downloads.atlassian.com/software/sourcetree/ga/Sourcetree_${version}.zip";
    sha256 = "sha256-bq3Z7p3lwBOEIee4xgo6gcxSjAq1R3dorVKzR8KAdTc=";
  };
  description = "Sourcetree is a free git GUI";
  homepage = "https://www.sourcetreeapp.com";
}
