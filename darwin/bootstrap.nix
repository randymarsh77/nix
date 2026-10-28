{ hostPlatform }:

{ pkgs, ... }:

let
  dotnetSdkVersion = "10.0.401";
  dotnetSdkPackage =
    let
      package = {
        aarch64-darwin = {
          architecture = "arm64";
          hash = "sha512-1DH3dPHvqNOjCsshfSRgYWDMhZKfmxB1AJQX6hzoltsmsBOYlx0Pmqi7lul7SQO1xQ3RVQ72xfqXYA9AxQj/gg==";
        };
        x86_64-darwin = {
          architecture = "x64";
          hash = "sha512-s4ZaEXtRQYY9vJf/dVf8yhas2XYeB8zusiqtpoBGH/TFQZoyhsYuIuNheW+d3ZYBlFHCzZq+hvbQF7FO6AjKsA==";
        };
      }.${hostPlatform};
    in
    pkgs.fetchurl {
      url = "https://builds.dotnet.microsoft.com/dotnet/Sdk/${dotnetSdkVersion}/dotnet-sdk-${dotnetSdkVersion}-osx-${package.architecture}.pkg";
      inherit (package) hash;
    };
in
{
  nix.settings = {
    substituters = [ "https://cache.nixos.org/" "https://randymarsh77.github.io/nix" ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      (builtins.replaceStrings [ "\n" ] [ "" ] (builtins.readFile ../.github/cache/public-key))
    ];
    experimental-features = "nix-command flakes";
  };

  # Auto upgrade nix package and the daemon service.
  nix.package = pkgs.nix;

  environment.systemPath = [ "/usr/local/share/dotnet" ];

  # Create /etc/zshrc that loads the nix-darwin environment.
  programs.zsh.enable = true; # default shell on catalina
  programs.zsh.promptInit = ''
    source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
    autoload -U compinit; compinit
    source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh
  '';

  programs.fish.enable = true;

  programs.direnv.enable = true;

  system.activationScripts.postActivation.text = ''
    if [ ! -d "/usr/local/share/dotnet/sdk/${dotnetSdkVersion}" ]; then
      echo "Installing official .NET SDK ${dotnetSdkVersion}..."
      /usr/sbin/installer -pkg "${dotnetSdkPackage}" -target /
    fi
  '';

  # Set Git commit hash for darwin-version.
  #   system.configurationRevision = self.rev or self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  nixpkgs.hostPlatform = hostPlatform;
  nixpkgs.config.allowUnfree = true;
}
