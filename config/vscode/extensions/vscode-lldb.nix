{ pkgs }:
with pkgs;
with pkgs.vscode-extensions;
let
  inherit (stdenv.hostPlatform) system;
  version = "1.8.1";

  vsixInfo = let
  in {
    x86_64-darwin = {
      url =
        "https://github.com/vadimcn/vscode-lldb/releases/download/v${version}/codelldb-x86_64-darwin.vsix";
      sha256 = "FzWpvnmS7w+NibkNw1LlmivEG+ZJBERI5M2WbdAOBU0=";
    };
    aarch64-darwin = {
      url =
        "https://github.com/vadimcn/vscode-lldb/releases/download/v${version}/codelldb-aarch64-darwin.vsix";
      sha256 = "IOvVjrnzDjWCC9fnDcsq0dbcn7Xo9W9+/B67+WeeGEU=";
    };
  }.${system} or (throw "Unsupported system: ${system}");

in vscode-utils.buildVscodeMarketplaceExtension rec {
  mktplcRef = {
    name = "vscode-lldb";
    publisher = "vadimcn";
    inherit version;
  };

  vsix = fetchurl {
    name = "${mktplcRef.publisher}-${mktplcRef.name}.zip";
    inherit (vsixInfo) url sha256;
  };

  meta = with lib; {
    description = "A native debugger extension for VSCode based on LLDB";
    homepage = "https://github.com/vadimcn/vscode-lldb";
    license = licenses.mit;
    maintainers = [ ];
    platforms = [ "x86_64-darwin" "aarch64-darwin" ];
  };
}
