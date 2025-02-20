#!/usr/bin/env bash
set -euo pipefail

get_current_version() {
    local publisher="$1"
    local name="$2"
    local nixfile="${0%/*}/default.nix"
    
    # Extract version from the matching extension block
    awk -v pub="$publisher" -v n="$name" '
        $0 ~ "publisher = \"" pub "\"" { found = 1 }
        found && $0 ~ "name = \"" n "\"" { name_match = 1 }
        name_match && $0 ~ /version =/ { 
            split($0, arr, "\"")
            print arr[2]
            exit
        }
    ' "$nixfile"
}

get_latest_version() {
    local publisher="$1"
    local name="$2"
    
    # Fetch the extension page and extract version
    curl -s "https://marketplace.visualstudio.com/items?itemName=${publisher}.${name}" | 
        grep -o '"version":"[^"]*"' | 
        head -n1 | 
        cut -d'"' -f4
}

get_sha256() {
    local publisher="$1"
    local name="$2"
    local version="$3"
    
    # Create tempdir in home directory
    local exttmp
    exttmp=$(mktemp -d "$HOME/.vscode_ext_tmp.XXXXXX")
    
    # Download the extension
    local url="https://${publisher}.gallery.vsassets.io/_apis/public/gallery/publisher/${publisher}/extension/${name}/${version}/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage"
    if ! curl --silent --show-error --fail -X GET -o "${exttmp}/${name}.zip" "$url"; then
        rm -rf "$exttmp"
        return 1
    fi
    
    # Calculate the SHA in base64
    local sha_base64
    sha_base64=$(nix-hash --flat --base64 --type sha256 "${exttmp}/${name}.zip")
    
    # Clean up
    rm -rf "$exttmp"
    
    echo "sha256-${sha_base64}"
}

update_extension() {
    local publisher="$1"
    local name="$2"
    
    local current_version
    current_version=$(get_current_version "$publisher" "$name")
    
    echo "Checking ${publisher}.${name}..."
    
    local latest_version
    latest_version=$(get_latest_version "$publisher" "$name")
    
    if [ "$current_version" != "$latest_version" ]; then
        echo "Update available: ${current_version} -> ${latest_version}"
        local new_sha
        new_sha=$(get_sha256 "$publisher" "$name" "$latest_version")
        
        echo "New SHA256: ${new_sha}"
        
        # Update the version and SHA in the file
        local nixfile="${0%/*}/default.nix"
        
        # Create a temporary file for the sed script in home directory
        local temp_script
        temp_script=$(mktemp "$HOME/.vscode_sed_tmp.XXXXXX")
        {
            echo "/publisher = \"${publisher}\"/{" # Find publisher line
            echo "  n" # Move to name line
            echo "  /name = \"${name}\"/{" # Check if it's the right name
            echo "    n" # Move to version line
            echo "    s/version = \"${current_version}\"/version = \"${latest_version}\"/" # Update version
            echo "    n" # Move to sha256 line
            echo "    s|sha256 = \".*\"|sha256 = \"${new_sha}\"|" # Update sha256
            echo "  }"
            echo "}"
        } > "$temp_script"
        
        sed -i.bak -f "$temp_script" "$nixfile"
        rm "$temp_script" "${nixfile}.bak"
        
        echo "Updated ${publisher}.${name} to version ${latest_version}"
    else
        echo "Already up to date"
    fi
}

get_all_extensions() {
    local nixfile="${0%/*}/default.nix"
    
    # Extract all publisher/name pairs from extensionsFromVscodeMarketplace blocks
    awk '
        /extensionsFromVscodeMarketplace/ { in_block = 1 }
        in_block && /publisher = "/ {
            split($0, arr, "\"")
            publisher = arr[2]
        }
        in_block && /name = "/ {
            split($0, arr, "\"")
            print publisher " " arr[2]
        }
    ' "$nixfile"
}

# Update all marketplace extensions
while read -r line; do
    [[ -z "$line" ]] && continue
    read -r publisher name <<< "$line"
    update_extension "$publisher" "$name"
done < <(get_all_extensions)
