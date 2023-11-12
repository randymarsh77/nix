{ writeShellScriptBin }:

# Use file aliases for symlinked applications in order to gain visiblility in Spotlight
# Credit: https://github.com/LnL7/nix-darwin/issues/214#issuecomment-1230730292
# Notes:
#  This script is adapted from the original and provided as a separate command instead of an activation script.
#  - Separate command: Running as an activation script requires GUI elevation twice per app. This is unnacceptable.
#  - Adaptation: Since this is a separate command run as your user, we don't need to elevate. However, it also means
#                the files have different ownership, which would break darwin-rebuild's ability to set up the app symlinks.
#                To work around that, we simply use a different directory to manage the aliases. 
writeShellScriptBin "refresh-spotlight" ''
  echo "Adding Nix apps for Spotlight..."
  NIX_APP_ALIASES="/Applications/Nix Apps Aliases"
  NIX_APPS=$(readlink "/Applications/Nix Apps")

  # Delete the directory to remove old aliases
  echo "Removing $NIX_APP_ALIASES:"
  rm -rf "$NIX_APP_ALIASES"
  mkdir -p "$NIX_APP_ALIASES"
  find "$NIX_APPS" -maxdepth 1 -type l -exec readlink '{}' + |
      while read APP_SRC; do
          echo "Creating alias for $APP_SRC"
          /usr/bin/osascript -e "
              set fileToAlias to POSIX file \"$APP_SRC\" 
              set applicationsFolder to POSIX file \"$NIX_APP_ALIASES\"
              tell application \"Finder\"
                  make alias file to fileToAlias at applicationsFolder
                  # This renames the alias; 'mpv.app alias' -> 'mpv.app'
                  set name of result to \"$(rev <<< "$APP_SRC" | cut -d'/' -f1 | rev)\"
              end tell
          " 1>/dev/null
      done
''
