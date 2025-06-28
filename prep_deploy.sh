#!/bin/bash

# set -x # Enable debugging output

################################################################################################################
#
# This script accept below options:
# 1. --source: The source directory to copy files from. Must be a Git repository. Must be an absolute path. Mandatory.
# 2. --out: The output directory to copy files to (aka deployment folder). Must be an absolute path. Mandatory.
# 3. --git-target: The target branch for the Git repository. Mandatory.
# 4. --git-incoming: The incoming branch for the Git repository. Mandatory.
# 5. --module: The module name to be used in the output directory. Optional.
#                If not provided, the script will guess it from the Git remote URL.
#
# Usage: ./prep_deploy.sh --source /path/to/source/ --out /path/to/out/ --git-target target_branch --git-incoming incoming_branch
#
# The script will Git list the files changed between the target and incoming
# branches. It will write the list of files to a file called "diff_files.txt"
# in the /path/to/out/_backup/ directory.
#
# Then, it will prepare the deployment folder in accordance to MYwave deployment SOP.
# - Checkout the target branch and copy all changed files to the /path/to/out/suite1/ directory.
# - Checkout the incoming branch and copy all changed files to the /path/to/out/azureDev/ directory.
# - It also creates a directory called _sql/ in the /path/to/out/ directory. All migration scripts should be placed in this directory.
#
# Exit codes:
# 1: Unknown option
# 2: Invalid option value
#
################################################################################################################

# CONSTANTS
PROD_BACKUP_DIR="suite1"
DEVELOPMENT_DIR="azureDev"
MIGRATION_DIR="_sql"
README_DIR="_readme"

# Functions declaration

# Display usage information
usage() {
    echo "Usage: $0 --source /path/to/source/ --out /path/to/out/ --git-target target_branch --git-incoming incoming_branch"
    echo "Options:"
    echo "  --source       The source directory to copy files from. Must be a Git repository. Must be an absolute path. Mandatory."
    echo "  --out          The output directory to copy files to. Must be an absolute path. Mandatory."
    echo "  --git-target   The target branch for the Git repository. Mandatory."
    echo "  --git-incoming The incoming branch for the Git repository. Mandatory."
    echo "  --module       The module name to be used in the output directory. Optional."
    echo "                   If not provided, the script will guess it from the Git remote URL."
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
            --module)
                MODULE_NAME="$2"
                shift 2
                ;;
            *)
                echo "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done

    # Check if mandatory options are provided
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
    [[ -n "$MODULE_NAME" ]] && echo "Module Name: $MODULE_NAME"
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

# Clean the output directory
clean_out_dir() {
    if [[ -d "$OUT_DIR" ]]; then
      echo "Output directory '$OUT_DIR' already exists."

      # Ask for confirmation before deleting the output directory. Exit if reject.
      read -p "Do you want to delete it? DANGER! PERMANENT DELETE AND CANNOT BE UNDONE! (y/n): " confirm
      if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
          echo "Deleting existing output directory '$OUT_DIR'..."
          rm -rf "$OUT_DIR"
      else
          echo "Phew... Exiting. Kindly provide a safe output directory to prepare the deployment."
          exit 0
      fi
    fi

    # Create the output directory
    mkdir -p "$OUT_DIR" && echo -e "Created output directory '$OUT_DIR'.\n"
}

# List Git changed files between two Git branches
list_git_changed_files() {
    local target_branch="$1"
    local incoming_branch="$2"
    local diff_file="$OUT_DIR/$README_DIR/diff_files.txt"

    echo "Listing changed files between branches '$target_branch' and '$incoming_branch'..."

    # Ensure the directory exists. Create the file.
    mkdir -p "$(dirname "$diff_file")" && touch "$diff_file"

    # Change to the source directory
    cd "$SOURCE_DIR" || exit 2

    # List changed files and write to the file
    git diff --name-status "$target_branch" "$incoming_branch" > "$diff_file"

    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to list changed files between branches '$target_branch' and '$incoming_branch'."
        exit 2
    fi

    echo "Changed files have been written to '$diff_file'. Summary below:"
    cat "$diff_file"
    echo "" # Add an empty line for better readability
}

# Prepare deployment folder according to MYwave deployment SOP
prepare_deployment_folder() {
    echo "Preparing the deployment folder..."

    echo "" # Add an empty line for better readability

    # Create output directories
    mkdir -p "$OUT_DIR/$PROD_BACKUP_DIR/$MODULE_NAME" "$OUT_DIR/$DEVELOPMENT_DIR/$MODULE_NAME"

    # Checkout the target branch and copy changed files to production backup directory
    echo "Checking out target branch '$GIT_TARGET' and copying changed files to '$OUT_DIR/$PROD_BACKUP_DIR/$MODULE_NAME'..."
    git -C "$SOURCE_DIR" checkout --quiet "$GIT_TARGET"

    # Copy changed files from diff_files.txt
    while IFS= read -r line; do
        file_path=$(echo "$line" | awk '{print $2}')
        if [[ -f "$SOURCE_DIR/$file_path" ]]; then
            mkdir -p "$OUT_DIR/$PROD_BACKUP_DIR/$MODULE_NAME/$(dirname "$file_path")"
            cp "$SOURCE_DIR/$file_path" "$OUT_DIR/$PROD_BACKUP_DIR/$MODULE_NAME/$file_path" && echo "Copied file: $file_path to $OUT_DIR/$PROD_BACKUP_DIR/$MODULE_NAME/$file_path" 
        fi
    done < "$OUT_DIR/$README_DIR/diff_files.txt"
    echo "" # Add an empty line for better readability

    # Checkout the incoming branch and copy changed files to development directory
    echo "Checking out incoming branch '$GIT_INCOMING' and copying changed files to '$OUT_DIR/$DEVELOPMENT_DIR/$MODULE_NAME'..."
    git -C "$SOURCE_DIR" checkout --quiet "$GIT_INCOMING"
    
    # Copy changed files from diff_files.txt
    while IFS= read -r line; do
        file_path=$(echo "$line" | awk '{print $2}')
        if [[ -f "$SOURCE_DIR/$file_path" ]]; then
            mkdir -p "$OUT_DIR/$DEVELOPMENT_DIR/$MODULE_NAME/$(dirname "$file_path")"
            cp "$SOURCE_DIR/$file_path" "$OUT_DIR/$DEVELOPMENT_DIR/$MODULE_NAME/$file_path" && echo "Copied file: $file_path to $OUT_DIR/$DEVELOPMENT_DIR/$MODULE_NAME/$file_path"
        fi
    done < "$OUT_DIR/$README_DIR/diff_files.txt"
    echo "" # Add an empty line for better readability

    # Create the migration scripts directory
    mkdir -p "$OUT_DIR/$MIGRATION_DIR" && echo "Created directory '$OUT_DIR/$MIGRATION_DIR'."

    echo "Deployment folder prepared successfully."
    echo "" # Add an empty line for better readability

    # Remind to manually remove the deleted files from the server if diff_files.txt contains any deleted files
    if grep -q "^D" "$OUT_DIR/$README_DIR/diff_files.txt"; then
        echo "Reminder: Please manually remove the files that were deleted from the server."
    fi
}

# Guess the module name if not provided from git remote URL
guess_module_name() {
    local guessed_mod_name=""

    if [[ -z "$MODULE_NAME" ]]; then
        echo "Module name not provided. Guessing it from the Git remote URL..."
        guessed_mod_name=$(basename "$(git -C "$SOURCE_DIR" config --get remote.origin.url)" .git)

        guessed_mod_name=${guessed_mod_name//-//} # Replace all occurences - to /
        echo "Guessed module name: $guessed_mod_name"

        MODULE_NAME="$guessed_mod_name"
        echo "" # Add an empty line for better readability
    fi
}

################################################################################################################

# Main script execution

read_options "$@"

clean_out_dir

check_git_repository

guess_module_name

list_git_changed_files "$GIT_TARGET" "$GIT_INCOMING"

prepare_deployment_folder
