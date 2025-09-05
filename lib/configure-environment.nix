{ withShell ? "", withVSCodeSettings ? "{}", withDotFiles ? [ ], home, pkgs, lib
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
  vscodeExtensions = buildEnv {
    name = "vscode-extensions";
    paths = (import ../config/vscode/extensions { pkgs = pkgs; });
  };

  createAllDotFiles = concatStrings (map ({ path, contents }:
    let
      source = builtins.toFile (builtins.baseNameOf path) contents;
      destination = path;
    in ''
      install-dot-file "${source}" "${destination}";
    '') withDotFiles);

  # Avoid vscode-with-extensions, which wraps code using --extensions-dir to a root-owned nix store.
  # Instead, copy the results of an equivalently built nix store into user-land and chown it.
  # Apply the same strategy for settings.
  script = builtins.replaceStrings [
    "@bashProfile@"
    "@zshProfile@"
    "@p10k@"
    "@createAllDotFiles@"
    "@home@"
    "@vscodeSettings@"
    "@vscodeExtensions@"
  ] [
    "${bashProfile}"
    "${zshProfile}"
    "${p10k}"
    "${createAllDotFiles}"
    "${home}"
    "${vscodeSettings}"
    "${vscodeExtensions}"
  ] (builtins.readFile ./configure-environment.sh);
in script
