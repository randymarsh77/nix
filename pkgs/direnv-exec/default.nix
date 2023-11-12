{ writeShellScriptBin }:

writeShellScriptBin "direnv-exec" ''
  shift # ignore the initial -c added by VS Code
  if [ -e /run/current-system/sw/bin/direnv ]; then
      direnv exec "$PROJ_DIR" $@
  else
      >&2 echo "direnv doesn't exist on your system as expected, however you are trying to use direnv-exec. Something has gone awry."
      exit 1
  fi
''
