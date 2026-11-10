#!/bin/bash

TARGET_USER=@primaryUser@

# Activation runs as root, so write dotfiles as the target user: they must stay
# user-owned and editable rather than root-owned copies of read-only store files.
copy-as-user() {
  install -o "$TARGET_USER" -m 0644 "$1" "$2";
}

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
      copy-as-user "$DESTINATION" "$BACKUP";
      copy-as-user "$SOURCE" "$DESTINATION";
      echo "✅ Updated $DESTINATION";
    else
      # Repair files left root-owned and read-only by earlier activations.
      chown "$TARGET_USER" "$DESTINATION";
      chmod u+w "$DESTINATION";
      echo "✅ $DESTINATION matches the configuration.";
    fi
  else
    sudo -u "$TARGET_USER" mkdir -p "$(dirname "$DESTINATION")";
    copy-as-user "$SOURCE" "$DESTINATION";
    echo "✅ Created $DESTINATION";
  fi
}

echo "Configuring shell profiles..."
install-dot-file @bashProfile@ @home@/.bash_profile
install-dot-file @zshProfile@ @home@/.zshrc
install-dot-file @p10k@ @home@/.p10k.zsh

echo "Copying dotfiles..."
@createAllDotFiles@

echo "Configuring VSCode user settings for '$TARGET_USER'..."
VSCODE_USER_SETTINGS_DIR=$(dirname @home@/Library/Application\ Support/Code/User/settings.json)
mkdir -p "$VSCODE_USER_SETTINGS_DIR"
install-dot-file @vscodeSettings@ "$VSCODE_USER_SETTINGS_DIR/settings.json"
VSCODE_SUPPORT_DIR=$(dirname "$VSCODE_USER_SETTINGS_DIR")
chown -R "$TARGET_USER" "$VSCODE_SUPPORT_DIR"
chmod +w "$VSCODE_SUPPORT_DIR"

echo "Configuring VSCode extensions..."
INSTALLED_EXTENSIONS=$(sudo -u "$TARGET_USER" env HOME=@home@ NODE_OPTIONS=--disable-warning=DEP0169 \
  @vscodeCommand@ --list-extensions)
INSTALL_ARGUMENTS=()
while IFS= read -r EXTENSION_ID; do
  [ -z "$EXTENSION_ID" ] && continue
  if ! grep -Fxiq -- "$EXTENSION_ID" <<< "$INSTALLED_EXTENSIONS"; then
    INSTALL_ARGUMENTS+=(--install-extension "$EXTENSION_ID")
  fi
done < @vscodeExtensionIds@

if [ ${#INSTALL_ARGUMENTS[@]} -gt 0 ]; then
  sudo -u "$TARGET_USER" env HOME=@home@ NODE_OPTIONS=--disable-warning=DEP0169 \
    @vscodeCommand@ "${INSTALL_ARGUMENTS[@]}"
else
  echo "All configured VSCode extensions are installed."
fi

echo "Updating installed VSCode extensions..."
sudo -u "$TARGET_USER" env HOME=@home@ NODE_OPTIONS=--disable-warning=DEP0169 \
  @vscodeCommand@ --update-extensions
