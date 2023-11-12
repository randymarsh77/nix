{ pkgs }:
let
  util = import ../util.nix { pkgs = pkgs; };
  version = "4.2.2_250";
in with util;
installApplication {
  name = "Sourcetree";
  version =
    version; # Update Feed: https://product-downloads.atlassian.com/software/sourcetree/Appcast/SparkleAppcastGroup4.xml
  sourceRoot = "Sourcetree.app";
  src = pkgs.fetchurl {
    url =
      "https://product-downloads.atlassian.com/software/sourcetree/ga/Sourcetree_${version}.zip";
    sha256 = "f70vdSbJJ7ycWH0kM2bT/NLx6imCO1Rw03S/uGfRR1g=";
  };
  description = "Sourcetree is a free git GUI";
  homepage = "https://www.sourcetreeapp.com";
}
