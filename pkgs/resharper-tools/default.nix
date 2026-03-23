{ pkgs }:
with pkgs;
let
  dotcover = callPackage ./dotcover { };
  dotmemory = callPackage ./dotmemory { };
  dottrace = callPackage ./dottrace { };
  resharper = callPackage ./resharper { };
in
{
  inherit
    dotcover
    dotmemory
    dottrace
    resharper
    ;
}
