# The Tailscale macOS app, with a `tailscale` command that follows the installed app.
#
# nixpkgs links bin/tailscale to the binary inside the store copy of the bundle. The app is
# copied into /Applications and updates itself there, so that link would drift away from the
# running app, and the binary does not reliably find its bundle when started through a symlink.
# Use a wrapper that runs the installed app's binary instead, as Tailscale's own CLI installer does.
{ tailscale-gui }:
tailscale-gui.overrideAttrs (old: {
  postInstall = (old.postInstall or "") + ''
    rm "$out/bin/tailscale"
    cat > "$out/bin/tailscale" <<EOF
    #!/bin/bash
    cli=/Applications/Tailscale.app/Contents/MacOS/Tailscale
    [ -x "\$cli" ] || cli=$out/Applications/Tailscale.app/Contents/MacOS/Tailscale
    exec "\$cli" "\$@"
    EOF
    chmod +x "$out/bin/tailscale"
  '';
})
