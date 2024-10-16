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
  script = ''
    install-dot-file() {
      local SOURCE="$1";
      local DESTINATION="$2";
      if [ -f "$DESTINATION" ]; then
        if [[ $(< "$DESTINATION") != "$(< "$SOURCE")" ]]; then
          local BACKUP;
          BACKUP="$DESTINATION.backup.$(date +"%Y-%m-%d_%H-%M-%S")";
          echo "❗The contents of $DESTINATION would be overwritten.";
          echo "  👉 Backing up $DESTINATION => $BACKUP)";
          echo "  👉 You should review the file differences and consider upstreaming any local changes."
          cp "$DESTINATION" "$BACKUP";
          cp "$SOURCE" "$DESTINATION";
          echo "✅ Updated $DESTINATION";
        else
          echo "✅ $DESTINATION matches the configuration.";
        fi
      else
        mkdir -p "$(dirname "$DESTINATION")";
        cp "$SOURCE" "$DESTINATION";
        echo "✅ Created $DESTINATION";
      fi
    }

    echo "Configuring shell profiles..."
    install-dot-file ${bashProfile} ${home}/.bash_profile
    install-dot-file ${zshProfile} ${home}/.zshrc
    install-dot-file ${p10k} ${home}/.p10k.zsh

    echo "Copying dotfiles..."
    ${createAllDotFiles}

    echo "Configuring VSCode user settings..."
    VSCODE_USER_SETTINGS_DIR=$(dirname ${home}/Library/Application\ Support/Code/User/settings.json)
    mkdir -p "$VSCODE_USER_SETTINGS_DIR"
    install-dot-file ${vscodeSettings} "$VSCODE_USER_SETTINGS_DIR/settings.json"
    VSCODE_SUPPORT_DIR=$(dirname "$VSCODE_USER_SETTINGS_DIR")
    chown -R $SUDO_USER "$VSCODE_SUPPORT_DIR"
    chmod +w "$VSCODE_SUPPORT_DIR"

    echo "Configuring VSCode extensions..."
    VSCODE_EXTENSIONS_DIR=$(dirname ${home}/.vscode/extensions/extensions.json)
    mkdir -p "$VSCODE_EXTENSIONS_DIR"
    rsync -av ${vscodeExtensions}/share/vscode/extensions/ "$VSCODE_EXTENSIONS_DIR"
    VSCODE_USER_DIR=$(dirname "$VSCODE_EXTENSIONS_DIR")
    chown -R $SUDO_USER "$VSCODE_USER_DIR"
    chmod +w "$VSCODE_USER_DIR"
    chmod +w "$VSCODE_EXTENSIONS_DIR"

    rm "$VSCODE_EXTENSIONS_DIR"/extensions.json &> /dev/null || :
    rm "$VSCODE_EXTENSIONS_DIR"/.init-default-profile-extensions &> /dev/null || :
  '';
in script
