{ pkgs }:
with pkgs;
with pkgs.vscode-extensions;
let
  inherit (stdenv.hostPlatform) system;
  version = "1.12.2";

  vsixInfo = let
  in {
    x86_64-darwin = {
      url =
        "https://github.com/vadimcn/vscode-lldb/releases/download/v${version}/codelldb-darwin-x64.vsix";
      sha256 = "sha256-gnCjQpKb3A3rbX05McCNW6YBgmX4QN0FCMQkf7jTLo0=";
    };
    aarch64-darwin = {
      url =
        "https://github.com/vadimcn/vscode-lldb/releases/download/v${version}/codelldb-darwin-arm64.vsix";
      sha256 = "sha256-yDa4HG8tpGe1kgo3anv8hJ3EtNgbGXed7fHGhctKoaA=";
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

  # Newer stdenv only unpacks `.zip` archives when `unzip` is available, and it
  # has no unpacker for a `.vsix` extension at all.
  nativeBuildInputs = [ unzip ];

  meta = with lib; {
    description = "A native debugger extension for VSCode based on LLDB";
    homepage = "https://github.com/vadimcn/vscode-lldb";
    license = licenses.mit;
    maintainers = [ ];
    platforms = [ "x86_64-darwin" "aarch64-darwin" ];
  };
}
