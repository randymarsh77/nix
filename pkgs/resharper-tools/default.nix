{ pkgs }:
with pkgs;
let
  dotcover = callPackage ./dotcover { };
  dotmemory = callPackage ./dotmemory { };
  dottrace = callPackage ./dottrace { };
in { inherit dotcover dotmemory dottrace; }
