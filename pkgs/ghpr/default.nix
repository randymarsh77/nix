{ writeShellScriptBin }:

# Checkout a PR using multiple choice
writeShellScriptBin "ghpr" ''
  gh pr list | fzf | cut -f1 | xargs gh pr checkout
''
