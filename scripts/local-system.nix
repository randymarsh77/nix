{ repo, config, nixbldGid, primaryUser }:
let
  flake = builtins.getFlake repo;
  localSystem = flake.darwinConfigurations.${config}.extendModules {
    modules = [
      {
        ids.gids.nixbld = nixbldGid;
        system.primaryUser = primaryUser;
      }
    ];
  };
in
localSystem.system
