{ darwin, intel-packages, arm-packages }:
{ hostPlatform, modules
, base ? (import ../darwin/bootstrap.nix { inherit hostPlatform; })
, systemPackages ? let
in {
  x86_64-darwin = intel-packages;
  aarch64-darwin = arm-packages;
}.${hostPlatform} or (throw "Unsupported system: ${hostPlatform}") }:
darwin.lib.darwinSystem { modules = [ base systemPackages ] ++ modules; }
