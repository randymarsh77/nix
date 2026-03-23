{ writeShellScriptBin }:

# Checkout a git branch using multiple choice
writeShellScriptBin "cb" ''
  git branch --list | fzf | cut -f1 | xargs git checkout
''
