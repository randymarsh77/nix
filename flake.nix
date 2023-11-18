{
  description = "X";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/master";
    nix-darwin.url = "github:LnL7/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    base.url = "github:randymarsh77/nix/master";
    base.inputs.nixpkgs.follows = "nixpkgs";

    localpkgs.url = "github:randymarsh77/nix/master?dir=pkgs";
    base.inputs.localpkgs.follows = "localpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, base, localpkgs }:
    with nixpkgs;
    with lib;
    let
      machine = "x";
      home = "/Users/matt";
      configuration = { pkgs, ... }: {
        # azure-cli is broken on Intel; filter it out.
        environment.systemPackages = builtins.filter (x: x != pkgs.azure-cli)
          base.constants.x86_64-darwin.default-packages;

        # Auto upgrade nix package and the daemon service.
        services.nix-daemon.enable = true;
        nix.package = pkgs.nix;

        # Necessary for using flakes on this system.
        nix.settings.experimental-features = "nix-command flakes";

        # Create /etc/zshrc that loads the nix-darwin environment.
        programs.zsh.enable = true; # default shell on catalina
        programs.fish.enable = true;

        # Set Git commit hash for darwin-version.
        system.configurationRevision = self.rev or self.dirtyRev or null;

        # Used for backwards compatibility, please read the changelog before changing.
        # $ darwin-rebuild changelog
        system.stateVersion = 4;

        # The platform the configuration will be used on.
        nixpkgs.hostPlatform = "x86_64-darwin";
        nixpkgs.config.allowUnfree = true;

        system.activationScripts.postActivation.text =
          base.lib.configure-environment {
            inherit home pkgs lib;
            withVSCodeSettings =
              (lib.fileContents ./config/vscode/settings.json);
          };
      };
    in {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#x
      darwinConfigurations.${machine} =
        nix-darwin.lib.darwinSystem { modules = [ configuration ]; };

      # Expose the package set, including overlays, for convenience.
      darwinPackages = self.darwinConfigurations.${machine}.pkgs;
    };
}
