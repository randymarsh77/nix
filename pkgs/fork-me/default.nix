{ writeShellScriptBin }:

writeShellScriptBin "fork-me" ''
  ORIGIN=$(git config --get remote.origin.url)
  ME=$(git config --get user.name)

  if [ -z "$ME" ]; then
    echo "Error: git config user.name is not set" >&2
    exit 1
  fi

  # Extract and replace the org from SSH (git@host:ORG/repo) or HTTPS (host/ORG/repo) URLs
  if echo "$ORIGIN" | grep -q "^git@"; then
    NEW=$(echo "$ORIGIN" | sed "s|:\([^/]*\)/|:$ME/|")
  else
    NEW=$(echo "$ORIGIN" | sed "s|\(.*/\)\([^/]*/\)|\1$ME/|")
  fi

  git remote add me "$NEW"
''
