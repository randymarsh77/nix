{ nixpkgs }:
with nixpkgs;
let
  defaultPackages = [
    # Essentials
    direnv
    direnv-exec
    nixfmt
    cachix
    git
    git-lfs
    gh
    git-absorb
    fzf

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
    resharper
    nbgv
    central-pkg-converter
    pwsh
    xstyler # xaml formatting

    # JS
    nodejs
    yarn
    bun

    # Go
    go
    goreleaser
    gopls
    delve

    # macOS
    xcode
    xcpretty
    tart
    orchard

    # Utility
    jq
    tailspin # log highlighting
    remote-build-flake # custom script to trigger remote flake builds
    fork-me
    cb
    ghpr
    discard-permission-only-changes
    dl-gha-logs
    mitmproxy
    packer
    ollama

    # Shell
    zsh-powerlevel10k
    zsh-fzf-tab

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
    sourcetree
    slack
  ];
in
defaultPackages
