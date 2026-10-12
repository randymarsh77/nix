{ withShell ? "", withVSCodeSettings ? "{}", withDotFiles ? [ ], primaryUser, home, pkgs, lib
}:
with pkgs;
with lib;
let
  bashProfile = builtins.toFile "profile.sh"
    ((fileContents ../config/shell/bash.sh) + ''

      ${withShell}
    '');
  zshProfile = builtins.toFile "profile.sh"
    ((fileContents ../config/shell/zsh.zsh) + ''

      ${withShell}
    '');
  p10k = builtins.toFile "p10k.zsh" (fileContents ../config/shell/p10k.zsh);

  vscodeSettings = builtins.toFile "settings.json" (builtins.toJSON
    ((builtins.fromJSON (builtins.readFile ../config/vscode/settings.json))
      // (builtins.fromJSON withVSCodeSettings)));
  vscodeExtensionIds = builtins.toFile "vscode-extension-ids"
    ((concatStringsSep "\n" (import ../config/vscode/extensions)) + "\n");

  createAllDotFiles = concatStrings (map ({ path, contents }:
    let
      source = builtins.toFile (builtins.baseNameOf path) contents;
      destination = path;
    in ''
      install-dot-file "${source}" "${destination}";
    '') withDotFiles);

  script = builtins.replaceStrings [
    "@bashProfile@"
    "@zshProfile@"
    "@p10k@"
    "@createAllDotFiles@"
    "@primaryUser@"
    "@home@"
    "@vscodeSettings@"
    "@vscodeCommand@"
    "@vscodeExtensionIds@"
  ] [
    "${bashProfile}"
    "${zshProfile}"
    "${p10k}"
    "${createAllDotFiles}"
    "${primaryUser}"
    "${home}"
    "${vscodeSettings}"
    "${pkgs.vscode}/bin/code"
    "${vscodeExtensionIds}"
  ] (builtins.readFile ./configure-environment.sh);
in script
