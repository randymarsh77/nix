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
            match($0, /"([^"]+)"/, arr)
            print arr[1]
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
    
    # Create a tempdir for the extension download
    local exttmp
    exttmp=$(mktemp -d -t vscode_exts_XXXXXXXX)
    
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
        
        # Create a temporary file for the sed script
        local temp_script=$(mktemp)
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
        in_block && /publisher = "([^"]+)"/ { 
            match($0, /"([^"]+)"/, arr)
            publisher = arr[1]
        }
        in_block && /name = "([^"]+)"/ {
            match($0, /"([^"]+)"/, arr)
            print publisher " " arr[1]
        }
    ' "$nixfile"
}

# Update all marketplace extensions
while read -r line; do
    [[ -z "$line" ]] && continue
    read -r publisher name <<< "$line"
    update_extension "$publisher" "$name"
done < <(get_all_extensions)
