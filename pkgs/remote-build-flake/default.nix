{ writeShellScriptBin, curl, coreutils }:

# Remote build trigger for arbitrary Nix flakes
# This script reads the local flake.nix file, base64-encodes it, and triggers a repository dispatch
# event to build the flake remotely on GitHub Actions runners with Cachix caching.
writeShellScriptBin "remote-build-flake" ''
  set -euo pipefail

  # Check if flake.nix exists in current directory
  if [ ! -f "flake.nix" ]; then
    echo "Error: flake.nix not found in current directory"
    echo "Please run this command from a directory containing a flake.nix file"
    exit 1
  fi

  # Check for required environment variables
  if [ -z "''${GITHUB_TOKEN:-}" ]; then
    echo "Error: GITHUB_TOKEN environment variable is required"
    echo "Please set GITHUB_TOKEN to a GitHub personal access token with repo permissions"
    exit 1
  fi

  # Repository configuration
  REPO_OWNER="randymarsh77"
  REPO_NAME="nix"

  echo "Reading flake.nix from current directory..."
  FLAKE_CONTENT=$(${coreutils}/bin/base64 -w 0 < flake.nix)

  echo "Triggering remote build for flake..."

  RESPONSE=$(${curl}/bin/curl -s -w "%{http_code}" -X POST \
    -H "Accept: application/vnd.github.v3+json" \
    -H "Authorization: token $GITHUB_TOKEN" \
    "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/dispatches" \
    -d "{\"event_type\":\"build-flake\",\"client_payload\":{\"flake\":\"$FLAKE_CONTENT\"}}")

  HTTP_CODE="''${RESPONSE: -3}"
  RESPONSE_BODY="''${RESPONSE%???}"

  if [ "$HTTP_CODE" = "204" ]; then
    echo "✅ Remote build triggered successfully!"
    echo "Check the Actions tab at: https://github.com/$REPO_OWNER/$REPO_NAME/actions"
    echo "Your flake will be built on both Intel and ARM runners with artifacts cached to Cachix."
  else
    echo "❌ Failed to trigger remote build (HTTP $HTTP_CODE)"
    if [ -n "$RESPONSE_BODY" ]; then
      echo "Response: $RESPONSE_BODY"
    fi
    exit 1
  fi
''
