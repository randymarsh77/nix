{ writeShellScriptBin }:

writeShellScriptBin "xcodebuild" ''
  ORIGINAL_ARGS="$@"
  env -i PATH=/bin:/usr/bin bash --norc --noprofile -c "xcodebuild $ORIGINAL_ARGS"
''
