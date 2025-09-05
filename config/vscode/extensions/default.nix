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
  bierner.markdown-mermaid
  brettm12345.nixfmt-vscode
  dbaeumer.vscode-eslint
  esbenp.prettier-vscode
  github.copilot
  github.copilot-chat
  hashicorp.terraform
  humao.rest-client
  jkillian.custom-local-formatters # Allows you to register arbitrary scripts as formatters
  jock.svg
  ms-azuretools.vscode-docker
  ms-dotnettools.csharp
  ms-dotnettools.vscode-dotnet-runtime
  ms-python.isort
  ms-python.python
  ms-python.vscode-pylance
  redhat.vscode-xml
  redhat.vscode-yaml
  shopify.ruby-lsp
  streetsidesoftware.code-spell-checker
  timonwong.shellcheck
  vscode-lldb
  wix.vscode-import-cost
  xaver.clang-format
  yzhang.markdown-all-in-one
] ++ vscode-utils.extensionsFromVscodeMarketplace [
  {
    publisher = "ccls-project";
    name = "ccls";
    version = "0.1.32";
    sha256 = "sha256-sCsRwS2z/jJpHeSuSdcitk39WEzKBiaZgt0gYRpViYU=";
  }
  {
    publisher = "christian-kohler";
    name = "npm-intellisense";
    version = "1.4.5";
    sha256 = "sha256-liuFGnyvvVHzSv60oLkemFyv85R+RiGKErRIUz2PYKs=";
  }
  {
    publisher = "christian-kohler";
    name = "path-intellisense";
    version = "2.10.0";
    sha256 = "sha256-bE32VmzZBsAqgSxdQAK9OoTcTgutGEtgvw6+RaieqRs=";
  }
  {
    publisher = "davedunkin";
    name = "facility-vscode";
    version = "0.2.1";
    sha256 = "sha256-+W3L0o0fv+91STGNoEuDS255vgs2ORjRYj9CTF5FR7Q=";
  }
  {
    publisher = "editorconfig";
    name = "editorconfig";
    version = "0.17.2";
    sha256 = "sha256-Xi2+mN6zjIKm0HWxfRAFs2vYkZ10Gv6poR2b2d8XCug=";
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
    publisher = "ms-vscode-remote";
    name = "remote-containers";
    version = "0.412.0";
    sha256 = "sha256-doAOyPtC54t0NBYNmV1S5ZoARIX1pcvRhbFXYSMKoSY=";
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
    version = "1.5.5";
    sha256 = "sha256-A2Fse+KBUWr+ViQ8JTKoFQAxfYriikhNx1lh5HtLHxc=";
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
    version = "0.0.59";
    sha256 = "sha256-dGcARuJ1HLWYwrz2T0HMos2vYxJCMJp8u0RzrDsw6NY=";
  }
  {
    publisher = "waderyan";
    name = "gitblame";
    version = "11.1.2";
    sha256 = "sha256-TlvMyFmtJQtpsjbdh3bPiRaMHro0M7gKOgtGc2bQLN4=";
  }
  {
    publisher = "mathiasfrohlich";
    name = "kotlin";
    version = "1.7.1";
    sha256 = "sha256-MuAlX6cdYMLYRX2sLnaxWzdNPcZ4G0Fdf04fmnzQKH4=";
  }
])
