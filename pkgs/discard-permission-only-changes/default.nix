{ writeShellScriptBin }:

let
  script = builtins.readFile ./discard-permission-only-changes.sh;
in
writeShellScriptBin "discard-permission-only-changes" script
