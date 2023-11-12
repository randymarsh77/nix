{ }:
let
  configure-environment = import ./configure-environment.nix;
  lib = { inherit configure-environment; };
in lib
