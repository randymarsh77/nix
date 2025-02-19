{ pkgs }:
with pkgs;
with dotnetCorePackages;
combinePackages [ sdk_8_0 sdk_9_0 ]
