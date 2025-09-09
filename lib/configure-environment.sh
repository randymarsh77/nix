#!/bin/bash

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
install-dot-file @bashProfile@ @home@/.bash_profile
install-dot-file @zshProfile@ @home@/.zshrc
install-dot-file @p10k@ @home@/.p10k.zsh

echo "Copying dotfiles..."
@createAllDotFiles@

TARGET_USER=@primaryUser@
echo "Configuring VSCode user settings for '$TARGET_USER'..."
VSCODE_USER_SETTINGS_DIR=$(dirname @home@/Library/Application\ Support/Code/User/settings.json)
mkdir -p "$VSCODE_USER_SETTINGS_DIR"
install-dot-file @vscodeSettings@ "$VSCODE_USER_SETTINGS_DIR/settings.json"
VSCODE_SUPPORT_DIR=$(dirname "$VSCODE_USER_SETTINGS_DIR")
chown -R "$TARGET_USER" "$VSCODE_SUPPORT_DIR"
chmod +w "$VSCODE_SUPPORT_DIR"

echo "Configuring VSCode extensions..."
VSCODE_EXTENSIONS_DIR=$(dirname @home@/.vscode/extensions/extensions.json)
mkdir -p "$VSCODE_EXTENSIONS_DIR"
rsync -avL @vscodeExtensions@/share/vscode/extensions/ "$VSCODE_EXTENSIONS_DIR"
VSCODE_USER_DIR=$(dirname "$VSCODE_EXTENSIONS_DIR")
chown -R "$TARGET_USER" "$VSCODE_USER_DIR"
chmod +w "$VSCODE_USER_DIR"
chmod +w "$VSCODE_EXTENSIONS_DIR"

# Create dated backups for VSCode extension files
if [ -f "$VSCODE_EXTENSIONS_DIR/extensions.json" ]; then
  BACKUP_FILE="$VSCODE_EXTENSIONS_DIR/extensions.json.backup.$(date +"%Y-%m-%d_%H-%M-%S")"
  echo "  👉 Backing up extensions.json => $BACKUP_FILE"
  cp "$VSCODE_EXTENSIONS_DIR/extensions.json" "$BACKUP_FILE"
fi
if [ -f "$VSCODE_EXTENSIONS_DIR/.init-default-profile-extensions" ]; then
  BACKUP_FILE="$VSCODE_EXTENSIONS_DIR/.init-default-profile-extensions.backup.$(date +"%Y-%m-%d_%H-%M-%S")"
  echo "  👉 Backing up .init-default-profile-extensions => $BACKUP_FILE"
  cp "$VSCODE_EXTENSIONS_DIR/.init-default-profile-extensions" "$BACKUP_FILE"
fi
rm "$VSCODE_EXTENSIONS_DIR"/extensions.json &> /dev/null || :
rm "$VSCODE_EXTENSIONS_DIR"/.init-default-profile-extensions &> /dev/null || :
