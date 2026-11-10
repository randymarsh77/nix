# Replaces nix-darwin's system/applications.nix.
#
# nix-darwin syncs every app bundle into /Applications/Nix Apps on each activation, overwriting
# whatever is there (which requires the App Management permission) and leaving the bundles
# root-owned and read-only. Most of these apps update themselves, so instead we install the ones
# that are missing straight into /Applications, owned by the user and writable, and leave
# existing bundles alone. To get the configured version of an app back, delete it and apply again.
{
  config,
  lib,
  pkgs,
  ...
}:

{
  disabledModules = [ "system/applications.nix" ];

  config = {
    system.build.applications = pkgs.buildEnv {
      name = "system-applications";
      paths = config.environment.systemPackages;
      pathsToLink = [ "/Applications" ];
    };

    system.activationScripts.applications.text = ''
      # Set up applications.
      echo "setting up /Applications..." >&2

      sourceFolder=${config.system.build.applications}/Applications
      targetFolder=/Applications
      legacyFolder='/Applications/Nix Apps'

      # Apps must belong to the person using them so that they can update themselves.
      owner=${lib.escapeShellArg (if config.system.primaryUser != null then config.system.primaryUser else "")}
      if [ -z "$owner" ]; then owner=''${SUDO_USER:-}; fi
      if [ -z "$owner" ] || [ "$owner" = root ]; then owner=$(stat -f %Su /dev/console); fi

      # Remove the folder that nix-darwin used to manage, whether a store symlink or synced copies.
      if [ -L "$legacyFolder" ]; then
        rm "$legacyFolder"
      elif [ -d "$legacyFolder" ]; then
        if rm -rf "$legacyFolder" 2> /dev/null; then
          echo "removed $legacyFolder: apps are now installed in $targetFolder" >&2
        else
          echo "warning: could not remove $legacyFolder; delete it to avoid duplicate apps" >&2
        fi
      fi

      rsyncFlags=(
        # Converts all symlinks pointing outside of the copied tree (thus unsafe) into real files and directories.
        # This neatly converts all the symlinks pointing to application bundles in the nix store into
        # real directories, without breaking any relative symlinks inside of application bundles.
        --copy-unsafe-links
        --archive
        # Store files are read-only.
        --chmod=u+w
        --no-group
        --no-owner
      )

      for source in "$sourceFolder"/*.app; do
        [ -e "$source" ] || continue
        name=$(basename "$source")
        target="$targetFolder/$name"
        if [ -e "$target" ]; then
          echo "skipping $name: already installed (delete it and apply again to reinstall the configured version)" >&2
          continue
        fi

        # Copy under a temporary name so an interrupted copy is never mistaken for an installed app.
        partial="$targetFolder/.$name.partial"
        rm -rf "$partial"
        ${lib.getExe pkgs.rsync} "''${rsyncFlags[@]}" "$source/" "$partial"
        chown -R "$owner" "$partial"
        mv "$partial" "$target"
        echo "installed $name" >&2
      done
    '';
  };
}
