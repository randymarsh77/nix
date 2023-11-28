{ darwin, intel-packages, arm-packages }:
let
  configure-environment = import ./configure-environment.nix;
  make-darwin-system = (import ./make-darwin-system.nix) {
    inherit darwin intel-packages arm-packages;
  };
in { inherit configure-environment make-darwin-system; }
