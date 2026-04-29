#!/bin/bash

# Script to download the N most recent GitHub Actions workflow run logs
# Usage: ./download-workflow-logs.sh [repository] [number_of_runs] [workflow_name]
# Example: ./download-workflow-logs.sh owner/repo 5
# Example: ./download-workflow-logs.sh owner/repo 10 "CI"

set -e

# Default values
DEFAULT_RUNS=5
LOGS_DIR="run-logs"

# Parse arguments
REPOSITORY=${1:-}
NUM_RUNS=${2:-$DEFAULT_RUNS}
WORKFLOW_NAME=${3:-}

# Function to show usage
show_usage() {
    echo "Usage: $0 [repository] [number_of_runs] [workflow_name]"
    echo ""
    echo "Arguments:"
    echo "  repository      GitHub repository in format owner/repo (optional if run from repo directory)"
    echo "  number_of_runs  Number of recent runs to download (default: $DEFAULT_RUNS)"
    echo "  workflow_name   Specific workflow name to filter by (optional)"
    echo ""
    echo "Examples:"
    echo "  $0 owner/repo 5"
    echo "  $0 owner/repo 10 \"CI\""
    echo "  $0 \"\" 3  # Use current repository, download 3 most recent runs"
    echo ""
    echo "The logs will be saved to the '$LOGS_DIR' directory."
}

# Check if help is requested
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_usage
    exit 0
fi

# Validate number of runs
if ! [[ "$NUM_RUNS" =~ ^[0-9]+$ ]] || [ "$NUM_RUNS" -lt 1 ]; then
    echo "Error: Number of runs must be a positive integer"
    exit 1
fi

# Build the repository flag
REPO_FLAG=""
if [[ -n "$REPOSITORY" ]]; then
    REPO_FLAG="--repo $REPOSITORY"
fi

# Build the workflow flag
WORKFLOW_FLAG=""
if [[ -n "$WORKFLOW_NAME" ]]; then
    WORKFLOW_FLAG="--workflow $WORKFLOW_NAME"
fi

echo "Downloading logs for $NUM_RUNS most recent workflow runs..."
if [[ -n "$REPOSITORY" ]]; then
    echo "Repository: $REPOSITORY"
fi
if [[ -n "$WORKFLOW_NAME" ]]; then
    echo "Workflow: $WORKFLOW_NAME"
fi

# Create logs directory
mkdir -p "$LOGS_DIR"

# Get the list of recent runs in JSON format
echo "Fetching workflow runs..."
RUNS_JSON=$(gh run list $REPO_FLAG $WORKFLOW_FLAG --limit "$NUM_RUNS" --json databaseId,number,displayTitle,workflowName,conclusion,createdAt,headBranch,headSha)

# Check if we got any runs
if [[ $(echo "$RUNS_JSON" | jq length) -eq 0 ]]; then
    echo "No workflow runs found."
    exit 0
fi

echo "Found $(echo "$RUNS_JSON" | jq length) runs to download..."

# Process each run
echo "$RUNS_JSON" | jq -r '.[] | @base64' | while IFS= read -r run_data; do
    # Decode the base64 encoded JSON
    run_info=$(echo "$run_data" | base64 --decode)
    
    # Extract run details
    database_id=$(echo "$run_info" | jq -r '.databaseId')
    run_number=$(echo "$run_info" | jq -r '.number')
    display_title=$(echo "$run_info" | jq -r '.displayTitle')
    workflow_name=$(echo "$run_info" | jq -r '.workflowName')
    conclusion=$(echo "$run_info" | jq -r '.conclusion')
    created_at=$(echo "$run_info" | jq -r '.createdAt')
    head_branch=$(echo "$run_info" | jq -r '.headBranch')
    head_sha=$(echo "$run_info" | jq -r '.headSha')
    
    # Create a safe filename
    safe_title=$(echo "$display_title" | sed 's/[^a-zA-Z0-9._-]/_/g')
    safe_workflow=$(echo "$workflow_name" | sed 's/[^a-zA-Z0-9._-]/_/g')
    timestamp=$(echo "$created_at" | sed 's/[T:]/-/g' | cut -d'.' -f1)
    
    log_filename="${run_number}_${safe_workflow}_${safe_title}_${timestamp}.log"
    log_path="$LOGS_DIR/$log_filename"
    
    echo "Downloading run #$run_number: $display_title ($conclusion)"
    echo "  Workflow: $workflow_name"
    echo "  Branch: $head_branch"
    echo "  SHA: $head_sha"
    echo "  Created: $created_at"
    echo "  Saving to: $log_path"
    
    # Create a header for the log file
    cat > "$log_path" << EOF
# GitHub Actions Workflow Run Log
# Run Number: $run_number
# Display Title: $display_title
# Workflow Name: $workflow_name
# Conclusion: $conclusion
# Branch: $head_branch
# SHA: $head_sha
# Created At: $created_at
# ================================================================================

EOF
    
    # Download the logs and append to the file
    if gh run view "$database_id" $REPO_FLAG --log >> "$log_path" 2>&1; then
        echo "  ✓ Successfully downloaded logs"
    else
        echo "  ✗ Failed to download logs (this may be normal for very old runs)"
        # Add error information to the log file
        echo "Error: Failed to download logs for this run." >> "$log_path"
        echo "This may happen if the logs have expired or are not available." >> "$log_path"
    fi
    
    echo ""
done

echo "Download completed! Logs saved in '$LOGS_DIR' directory."
echo ""
echo "Files created:"
ls -la "$LOGS_DIR"
