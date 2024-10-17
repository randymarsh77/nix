{ hostPlatform }:

{ pkgs, ... }:

{
  nix.settings = {
    substituters = [ "https://cache.nixos.org/" "https://preucil.cachix.org" ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "preucil.cachix.org-1:1Q+jMhn26yxSlYod9JnvhjKcSy4IpdW3eLZ3n3ARZ+0="
    ];
    experimental-features = "nix-command flakes";
  };

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  nix.package = pkgs.nix;

  # Create /etc/zshrc that loads the nix-darwin environment.
  programs.zsh.enable = true; # default shell on catalina
  programs.zsh.promptInit = ''
    source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
    autoload -U compinit; compinit
    source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh
  '';

  programs.fish.enable = true;

  # Set Git commit hash for darwin-version.
  #   system.configurationRevision = self.rev or self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  nixpkgs.hostPlatform = hostPlatform;
  nixpkgs.config.allowUnfree = true;
}
