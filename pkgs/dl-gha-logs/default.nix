{ writeShellScriptBin }:

let
  script = builtins.readFile ./download-workflow-logs.sh;
in
writeShellScriptBin "dl-gha-logs" script
