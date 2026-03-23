#!/bin/bash

# Get list of modified files
modified_files=$(git diff --name-only)

if [ -z "$modified_files" ]; then
    echo "No modified files found."
    exit 0
fi

echo "Checking for permission-only changes..."

for file in $modified_files; do
    # Get the diff for this file
    diff_output=$(git diff "$file")
    
    # Check if the diff contains only permission changes
    # Permission-only changes show as "old mode" and "new mode" lines with no content changes
    if echo "$diff_output" | grep -q "^old mode\|^new mode"; then
        # Check if there are any actual content changes (lines starting with + or - that aren't mode changes)
        content_changes=$(echo "$diff_output" | grep -E "^[+-]" | grep -v -E "^[+-]{3}|^old mode|^new mode")
        
        if [ -z "$content_changes" ]; then
            echo "Discarding permission-only changes for: $file"
            git checkout -- "$file"
        fi
    fi
done

echo "Done checking for permission-only changes."
