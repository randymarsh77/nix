{ nixpkgs, pkgs }:
with nixpkgs;
with pkgs;
let
  defaultPackages = [
    # Essentials
    direnv
    direnv-exec
    nixfmt
    git

    # Cloud
    azure-cli
    terraform
    kubectx
    kubelogin
    redis
    docker

    # .NET
    csharprepl
    dotnet
    dotcover
    dotmemory
    dottrace
    pwsh
    xstyler # xaml formatting

    # JS
    nodejs
    yarn

    # macOS
    xcode
    xcpretty

    # Utility
    jq
    tailspin # log highlighting

    # Apps
    # Note: If you change the list of GUI apps that you expect to see in Spotlight,
    #       you'll need to run refresh-spotlight after applying the updated config.
    refresh-spotlight
    vscode
    docker-desktop
    mysql-workbench-dist
    charles
    db-browser
    nitguard
  ];
in defaultPackages
