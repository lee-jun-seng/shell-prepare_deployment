#!/bin/bash

# set -x # Enable debugging output

################################################################################################################
#
# This script accept 4 options:
# 1. --source: The source directory to copy files from. Must be a Git repository. Must be an absolute path. Mandatory.
# 2. --out: The output directory to copy files to. Must be an absolute path. Mandatory.
# 3. --git-target: The target branch for the Git repository. Mandatory.
# 4. --git-incoming: The incoming branch for the Git repository. Mandatory.
#
# Usage: ./prep_deploy.sh --source /path/to/source/ --out /path/to/out/ --git-target target_branch --git-incoming incoming_branch
#
# The script will first check if the source directory is a Git repository.
# If it is, it will Git list the files changed between the target and incoming
# branches. It will write the list of files to a file called
# "diff_files.txt" in the /path/to/out/_backup/ directory.
#
# Exit codes:
# 1: Unknown option
# 2: Invalid option value
#
################################################################################################################

# Function to display usage information
usage() {
    echo "Usage: $0 --source /path/to/source/ --out /path/to/out/ --git-target target_branch --git-incoming incoming_branch"
    echo "Options:"
    echo "  --source       The source directory to copy files from. Must be a Git repository. Must be an absolute path. Mandatory."
    echo "  --out          The output directory to copy files to. Must be an absolute path. Mandatory."
    echo "  --git-target   The target branch for the Git repository. Mandatory."
    echo "  --git-incoming The incoming branch for the Git repository. Mandatory."
}

# Read options
read_options() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --source)
                SOURCE_DIR="$2"
                shift 2
                ;;
            --out)
                OUT_DIR="$2"
                shift 2
                ;;
            --git-target)
                GIT_TARGET="$2"
                shift 2
                ;;
            --git-incoming)
                GIT_INCOMING="$2"
                shift 2
                ;;
            *)
                echo "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done

    if [[ -z "$SOURCE_DIR" || -z "$OUT_DIR" || -z "$GIT_TARGET" || -z "$GIT_INCOMING" ]]; then
        usage
        exit 1
    fi

    # Display the options
    echo "Options:"
    echo "Source Directory: $SOURCE_DIR"
    echo "Output Directory: $OUT_DIR"
    echo "Git Target Branch: $GIT_TARGET"
    echo "Git Incoming Branch: $GIT_INCOMING"
    echo "" # Add an empty line for better readability
}

# Perform Git checks on the source directory
check_git_repository() {
    echo "Performing Git checks on the source directory '$SOURCE_DIR'..."

    # Check if is valid Git repository
    if [[ ! -d "$SOURCE_DIR/.git" ]]; then
        echo "Error: The source directory '$SOURCE_DIR' is not a Git repository."
        exit 2
    fi

    echo "Is a valid Git repository."

    # Check if the target branch exist in the Git repository
    if ! git -C "$SOURCE_DIR" show-ref --verify --quiet "refs/heads/$GIT_TARGET"; then
        echo "Error: The target branch '$GIT_TARGET' does not exist in the Git repository."
        exit 2
    fi

    echo "Target branch '$GIT_TARGET' exists."

    # Check if the incoming branch exists in the Git repository
    if ! git -C "$SOURCE_DIR" show-ref --verify --quiet "refs/heads/$GIT_INCOMING"; then
        echo "Error: The incoming branch '$GIT_INCOMING' does not exist in the Git repository."
        exit 2
    fi

    echo "Incoming branch '$GIT_INCOMING' exists."

    # Check if target and incoming branches are different
    if git -C "$SOURCE_DIR" diff --quiet "$GIT_TARGET" "$GIT_INCOMING"; then
        echo "Warning: The target branch '$GIT_TARGET' and incoming branch '$GIT_INCOMING' are the same. No changes to list."
        exit 0
    fi

    echo "Target and incoming branches are different."

    echo -e "Git checks completed successfully.\n"
}

# List Git changed files between two Git branches
list_git_changed_files() {
    local target_branch="$1"
    local incoming_branch="$2"
    local diff_file="$OUT_DIR/_backup/diff_files.txt"

    echo "Listing changed files between branches '$target_branch' and '$incoming_branch'..."

    # Ensure the output directory exists. Create the file.
    mkdir -p "$(dirname "$diff_file")" && touch "$diff_file"

    # Change to the source directory
    cd "$SOURCE_DIR" || exit 2

    # List changed files and write to the output file
    git diff --name-status "$target_branch" "$incoming_branch" > "$diff_file"

    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to list changed files between branches '$target_branch' and '$incoming_branch'."
        exit 2
    fi

    echo "Changed files have been written to '$diff_file'. Summary below:"
    cat "$diff_file"
}

################################################################################################################

# Main script execution

read_options "$@"

check_git_repository

list_git_changed_files "$GIT_TARGET" "$GIT_INCOMING"
