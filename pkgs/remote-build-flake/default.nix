{ writeShellScriptBin, curl, coreutils }:

# Remote build trigger for arbitrary Nix flakes
# This script reads the local flake.nix file, base64-encodes it, and triggers a repository dispatch
# event to build the flake remotely on GitHub Actions runners with Cachix caching.
writeShellScriptBin "remote-build-flake" ''
  # Substitute paths in the shell script
  export PATH=${curl}/bin:${coreutils}/bin:$PATH
  
  ${builtins.readFile ./remote-build-flake.sh}
''
