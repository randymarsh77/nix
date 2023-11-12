{ pkgs }:
with pkgs;
with pkgs.vscode-extensions;
let
  # Credit: https://github.com/microsoft/vscode/issues/57481#issuecomment-910883638
  loadAfter = deps: pkg:
    pkg.overrideAttrs (old: {
      nativeBuildInputs = old.nativeBuildInputs or [ ]
        ++ [ pkgs.jq pkgs.moreutils ];

      preInstall = old.preInstall or [ ] ++ [''
        jq '.extensionDependencies |= . + $deps' \
          --argjson deps ${lib.escapeShellArg (builtins.toJSON deps)} \
          package.json | sponge package.json
      ''];
    });
  vscode-lldb = (import ./vscode-lldb.nix { pkgs = pkgs; });
in vscode-utils.extensionsFromVscodeMarketplace [{
  publisher = "cab404";
  name = "vscode-direnv";
  version = "1.0.0";
  sha256 = "sha256-+nLH+T9v6TQCqKZw6HPN/ZevQ65FVm2SAo2V9RecM3Y=";
}] ++ map (loadAfter [ "cab404.vscode-direnv" ]) ([
  arrterian.nix-env-selector
  bbenoist.nix
  brettm12345.nixfmt-vscode
  dbaeumer.vscode-eslint
  esbenp.prettier-vscode
  github.copilot
  hashicorp.terraform
  jkillian.custom-local-formatters # Allows you to register arbitrary scripts as formatters
  jock.svg
  ms-azuretools.vscode-docker
  ms-dotnettools.csharp
  ms-python.python
  ms-python.vscode-pylance
  rebornix.ruby
  redhat.vscode-xml
  redhat.vscode-yaml
  streetsidesoftware.code-spell-checker
  timonwong.shellcheck
  vscode-lldb
  wingrunr21.vscode-ruby
  wix.vscode-import-cost
  xaver.clang-format
  yzhang.markdown-all-in-one
] ++ vscode-utils.extensionsFromVscodeMarketplace [
  {
    publisher = "ccls-project";
    name = "ccls";
    version = "0.1.29";
    sha256 = "RjMYBLgbi+lgPqaqN7yh8Q8zr9euvQ+YLEoQaV3RDOA=";
  }
  {
    publisher = "christian-kohler";
    name = "npm-intellisense";
    version = "1.4.3";
    sha256 = "cjqHFj3GDUVdJvqh/uBsROWtqdtRkGjEGcCjS7PzjRY=";
  }
  {
    publisher = "christian-kohler";
    name = "path-intellisense";
    version = "2.8.3";
    sha256 = "AUpbQs2jDYyT1YfBG61KsV6oivhf9DDbHWLnNDveoC8=";
  }
  {
    publisher = "davedunkin";
    name = "facility-vscode";
    version = "0.2.0";
    sha256 = "X4BnpegEC2kFOAtxBhC7X0/t6QV2domMTpPeWMEYATo=";
  }
  {
    publisher = "editorconfig";
    name = "editorconfig";
    version = "0.16.4";
    sha256 = "j+P2oprpH0rzqI0VKt0JbZG19EDE7e7+kAb3MGGCRDk=";
  }
  {
    publisher = "jakebathman";
    name = "mysql-syntax";
    version = "1.3.1";
    sha256 = "+jYAi7rOp/pTNw6ANmIrCEs9XmrxfV7LICUK4imVA10=";
  }
  {
    publisher = "josephwoodward";
    name = "vscodeilviewer";
    version = "0.0.1";
    sha256 = "PI6YFSFM+h8eu9YCXRUUSnwgeCsMKEILMjBNZLz9FR4=";
  }
  {
    publisher = "mariomatheu";
    name = "syntax-project-pbxproj";
    version = "0.1.3";
    sha256 = "pXdOYA7OhypP8SVeLWg9+GRscl6XRxIQi87OyCYfCrw=";
  }
  {
    publisher = "misogi";
    name = "ruby-rubocop";
    version = "0.8.6";
    sha256 = "6hgJzOerGCCXcpADnISa7ewQnRWLAn6k6K4kLJR09UI=";
  }
  {
    publisher = "mitaki28";
    name = "vscode-clang";
    version = "0.2.4";
    sha256 = "Q3R781Vxn4hQUHwCB+CbNmktWL5UACwmtVbZLQkU2ms=";
  }
  {
    publisher = "mrmlnc";
    name = "vscode-less";
    version = "0.6.3";
    sha256 = "CQxrg+rLfxjYgrXShC4RpS7nTzzsoyvsdM4EdNLIVEY=";
  }
  {
    publisher = "ms-python";
    name = "isort";
    version = "2022.8.0";
    sha256 = "l7mXTKdAE56DdnSaY1cs7sajhG6Yzz0XlZLtHY2saB0=";
  }
  {
    publisher = "ms-vscode-remote";
    name = "remote-containers";
    version = "0.266.1";
    sha256 = "D0nwLKGojvvRuviGRI9zo4SZmpZgee7ZpHLWjUK3LWA=";
  }
  {
    publisher = "ms-vscode";
    name = "mono-debug";
    version = "0.16.3";
    sha256 = "6IU8aP4FQVbEMZAgssGiyqM+PAbwipxou5Wk3Q2mjZg=";
  }
  {
    publisher = "puppet";
    name = "puppet-vscode";
    version = "1.4.0";
    sha256 = "+/JKKQy6DmgPqBDyFZRhUK5fO/szSCb7DJWRG3e6IEs=";
  }
  {
    publisher = "pvasek";
    name = "sourcekit-lsp--dev-unofficial";
    version = "0.20190711.1";
    sha256 = "0b5kSpRGHd0e38mIJlRY6B9h5QmjSCbl5HQypYwhmio=";
  }
  {
    publisher = "randymarsh77";
    name = "faithlife-build-tasks";
    version = "1.2.3";
    sha256 = "905rx2JMKD7VO5DOP6tdO97RQf0wVJwymD/6Wwk3Yrs=";
  }
  {
    publisher = "randymarsh77";
    name = "nuget-extensions-vscode";
    version = "0.1.2";
    sha256 = "VjapD2NlKUPk8r9vU3YhEtWmSiFaI0S2NidbfLKv81o=";
  }
  {
    publisher = "rogalmic";
    name = "bash-debug";
    version = "0.3.9";
    sha256 = "f8FUZCvz/PonqQP9RCNbyQLZPnN5Oce0Eezm/hD19Fg=";
  }
  {
    publisher = "vsls-contrib";
    name = "codetour";
    version = "0.0.58";
    sha256 = "Qd4L4nuPq7IP3sSNoLc5e3sEF9QV5hedRWnjAQWIGhY=";
  }
  {
    publisher = "waderyan";
    name = "gitblame";
    version = "10.0.0";
    sha256 = "TSHup8gf9RHKR0Y90QRY00D8/mXbyVZo7oBtQl9RXzg=";
  }
  {
    publisher = "mathiasfrohlich";
    name = "kotlin";
    version = "1.7.1";
    sha256 = "sha256-MuAlX6cdYMLYRX2sLnaxWzdNPcZ4G0Fdf04fmnzQKH4=";
  }
])
