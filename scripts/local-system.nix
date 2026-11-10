{ repo, config, nixbldGid }:
let
  flake = builtins.getFlake repo;
  localSystem = flake.darwinConfigurations.${config}.extendModules {
    modules = [ { ids.gids.nixbld = nixbldGid; } ];
  };
in
localSystem.system
