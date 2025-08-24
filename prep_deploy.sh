#!/bin/bash

# set -x # Enable debugging output

################################################################################################################
#
# The script will Git list the files changed between the target and incoming
# branches. It will write the list of files to a file called "diff_files.txt"
# in the /path/to/out/_readme/ directory. The script use this file to prepare the deployment folder.
#
# Then, it will prepare the deployment folder in accordance to MYwave deployment SOP.
# - Checkout the target branch and copy all changed files to the /path/to/out/suite1/ directory.
# - Checkout the incoming branch and copy all changed files to the /path/to/out/azureDev/ directory.
# - It also creates a directory called _sql/ in the /path/to/out/ directory. All migration scripts should be placed in this directory.
# - Prepare /path/to/out/_readme/deployment_instructions.md file with the deployment instructions if found deleted files that release manager needs to remove from server.
#
# This script accept below options:
# 1. -s, --source: The source directory to copy files from. Must be a Git repository. Must be an absolute path. Mandatory.
# 2. -o, --out: The output directory to copy files to (aka deployment folder). Must be an absolute path. Mandatory.
# 3. -t, --git-target: The target branch name for the Git repository. Mandatory.
# 4. -i, --git-incoming: The incoming branch name for the Git repository. Mandatory.
# 5. -m, --module: The module name to be used in the output directory. Optional. If not provided, the script will guess it from the Git remote URL.
# 6. -z, --ensure-prod-backup-latest: Ensure the latest production backup is same on the SFTP server. Optional. Default is no check.
#
# Usage: ./prep_deploy.sh --source /path/to/source/ --out /path/to/out/ --git-target target_branch --git-incoming incoming_branch [--module module_name] [--ensure-prod-backup-latest]
# Usage: ./prep_deploy.sh -s /path/to/source/ -o /path/to/out/ -t target_branch -i incoming_branch [-m module_name] [-z]
#
################################################################################################################

# CONSTANTS
PROD_BACKUP_DIR="suite1"
DEVELOPMENT_DIR="azureDev"
MIGRATION_DIR="_sql"
README_DIR="_readme"
ENSURE_PROD_BACKUP_LATEST=false

# Exit codes
EXIT_SUCCESS=0
EXIT_UNKNOWN_OPTION=1
EXIT_INVALID_OPTION_VALUE=2

# Functions declaration

# Function: usage
# Description: Displays the usage information for the script, including available options and their descriptions.
usage() {
  echo "Usage: $0 --source /path/to/source/ --out /path/to/out/ --git-target target_branch --git-incoming incoming_branch [--module module_name]"
  echo "Options:"
  echo "  -s, --source       The source directory to copy files from. Must be a Git repository. Must be an absolute path. Mandatory."
  echo "  -o, --out          The output directory to copy files to. Must be an absolute path. Mandatory."
  echo "  -t, --git-target   The target branch name for the Git repository. Mandatory."
  echo "  -i, --git-incoming The incoming branch name for the Git repository. Mandatory."
  echo "  -m, --module       The module name to be used in the output directory. Optional."
  echo "                       If not provided, the script will guess it from the Git remote URL."
}

# Function: read_options
# Description: Reads and parses command-line options for the script.
read_options() {
  while [[ $# -gt 0 ]]; do
    case $1 in
    --source | -s)
      SOURCE_DIR="$2"
      shift 2
      ;;
    --out | -o)
      OUT_DIR="$2"
      shift 2
      ;;
    --git-target | -t)
      GIT_TARGET="$2"
      shift 2
      ;;
    --git-incoming | -i)
      GIT_INCOMING="$2"
      shift 2
      ;;
    --module | -m)
      MODULE_NAME="$2"
      shift 2
      ;;
    --ensure-prod-backup-latest | -z)
      ENSURE_PROD_BACKUP_LATEST=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      usage
      exit $EXIT_UNKNOWN_OPTION
      ;;
    esac
  done

  # Check if mandatory options are provided
  if [[ -z "$SOURCE_DIR" || -z "$OUT_DIR" || -z "$GIT_TARGET" || -z "$GIT_INCOMING" ]]; then
    usage
    exit $EXIT_UNKNOWN_OPTION
  fi

  # Display the options
  echo "Options:"
  echo "Source Directory: $SOURCE_DIR"
  echo "Output Directory: $OUT_DIR"
  echo "Git Target Branch: $GIT_TARGET"
  echo "Git Incoming Branch: $GIT_INCOMING"
  if [[ -n "$MODULE_NAME" ]]; then
    echo "Module Name: $MODULE_NAME"
  else
    echo "Module Name: Not provided, will be guessed from Git remote URL."
  fi
  echo "" # Add an empty line for better readability
}

# Function: check_git_repository
# Description: Perform Git checks on the source directory
check_git_repository() {
  echo "Performing Git checks on the source directory '$SOURCE_DIR'..."

  # Check if is valid Git repository
  if [[ ! -d "$SOURCE_DIR/.git" ]]; then
    echo "Error: The source directory '$SOURCE_DIR' is not a Git repository."
    exit $EXIT_INVALID_OPTION_VALUE
  fi

  echo "Is a valid Git repository."

  # Check if the target branch exist in the Git repository
  if ! git -C "$SOURCE_DIR" show-ref --verify --quiet "refs/heads/$GIT_TARGET"; then
    echo "Error: The target branch '$GIT_TARGET' does not exist in the Git repository."
    exit $EXIT_INVALID_OPTION_VALUE
  fi

  echo "Target branch '$GIT_TARGET' exists."

  # Check if the incoming branch exists in the Git repository
  if ! git -C "$SOURCE_DIR" show-ref --verify --quiet "refs/heads/$GIT_INCOMING"; then
    echo "Error: The incoming branch '$GIT_INCOMING' does not exist in the Git repository."
    exit $EXIT_INVALID_OPTION_VALUE
  fi

  echo "Incoming branch '$GIT_INCOMING' exists."

  # Check if target and incoming branches are different
  if git -C "$SOURCE_DIR" diff --quiet "$GIT_TARGET" "$GIT_INCOMING"; then
    echo "Warning: The target branch '$GIT_TARGET' and incoming branch '$GIT_INCOMING' are the same. No changes to list."
    exit $EXIT_SUCCESS
  fi

  echo "Target and incoming branches are different."

  echo -e "Git checks completed successfully.\n"
}

# Function: clean_out_dir
# Description: Clean the output directory
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
      exit $EXIT_SUCCESS
    fi
  fi

  # Create the output directory
  mkdir -p "$OUT_DIR" && echo -e "Created output directory '$OUT_DIR'.\n"
}

# Function: list_git_changed_files
# Description: List Git changed files between two Git branches
# Parameters:
# 1. target_branch: The target branch to compare against
# 2. incoming_branch: The incoming branch to compare with the target branch
list_git_changed_files() {
  local target_branch="$1"
  local incoming_branch="$2"
  local diff_file="$OUT_DIR/$README_DIR/diff_files.txt"

  echo "Listing changed files between branches '$target_branch' and '$incoming_branch'..."

  # Ensure the directory exists. Create the file.
  mkdir -p "$(dirname "$diff_file")" && touch "$diff_file"

  # Change to the source directory
  cd "$SOURCE_DIR" || exit $EXIT_INVALID_OPTION_VALUE

  # List changed files and write to the file
  git diff --name-status "$target_branch" "$incoming_branch" >"$diff_file"

  if [[ $? -ne 0 ]]; then
    echo "Error: Failed to list changed files between branches '$target_branch' and '$incoming_branch'."
    exit $EXIT_INVALID_OPTION_VALUE
  fi

  echo "Changed files have been written to '$diff_file'. Summary below:"
  cat "$diff_file"
  echo "" # Add an empty line for better readability
}

# Function: prepare_deployment_instruction_file
# Description: Prepare deployment_instructions.md in the output directory
#              If the file does not exist, it will be created. Otherwise, it will be left as is.
prepare_deployment_instruction_file() {
  local instruction_file="$OUT_DIR/$README_DIR/deployment_instructions.md"

  # Create the deployment instructions file if it does not exist
  if [[ ! -f "$instruction_file" ]]; then
    mkdir -p "$(dirname "$instruction_file")" && touch "$instruction_file"

    echo "# Deployment Instructions" >"$instruction_file"
    echo "" >>"$instruction_file"

    echo "Created deployment instructions file at '$instruction_file'."
    echo "" # Add an empty line for better readability
  fi
}

# Function: prepare_deployment_folder
# Description: Prepare deployment folder according to MYwave deployment SOP
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
  done <"$OUT_DIR/$README_DIR/diff_files.txt"
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
  done <"$OUT_DIR/$README_DIR/diff_files.txt"
  echo "" # Add an empty line for better readability

  # Create the migration scripts directory
  mkdir -p "$OUT_DIR/$MIGRATION_DIR" && echo "Created directory '$OUT_DIR/$MIGRATION_DIR'."

  echo "Deployment folder prepared successfully."
  echo "" # Add an empty line for better readability

  # Remind to manually remove the deleted files from the server if diff_files.txt contains any deleted files
  if grep -q "^D" "$OUT_DIR/$README_DIR/diff_files.txt"; then
    prepare_deployment_instruction_file

    # Grep the deleted filenames and write to _README/deployment_instructions.md
    echo "- Please manually delete the following files from the server:" >>"$OUT_DIR/$README_DIR/deployment_instructions.md"
    grep "^D" "$OUT_DIR/$README_DIR/diff_files.txt" | awk '{print "  - "$2}' >>"$OUT_DIR/$README_DIR/deployment_instructions.md"
    echo "Reminder: Please remind release manager to manually delete the files from server."
  fi
}

# Function: guess_module_name
# Description: Guess the module name if not provided from git remote URL.
#              Expect - in the remote URL to be replaced directory separator.
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

# Function: check_prod_backup_latest
# Description: Ensure the latest production backup is same on the SFTP server
check_prod_backup_latest() {
  if [[ "$ENSURE_PROD_BACKUP_LATEST" == true ]]; then
    echo "Ensuring the latest production backup is available on the SFTP server..."
    tmp_dir="$(dirname "${BASH_SOURCE[0]}")"
    "$tmp_dir/libs/sftp_dl_cmp_files/sftp_dl_cmp_files.sh" -s "$tmp_dir/sftp.json" -d "$OUT_DIR/$PROD_BACKUP_DIR/$MODULE_NAME"
  fi
}

################################################################################################################

# Main script execution

read_options "$@"

# Request confirmation before proceeding
read -p "Kindly verify all parsed options before proceeding to preparing deployment folder. Do you want to proceed? (y/n): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
  echo "Exiting. No changes made."
  exit $EXIT_SUCCESS
fi
echo "" # Add an empty line for better readability

check_git_repository

clean_out_dir

guess_module_name

list_git_changed_files "$GIT_TARGET" "$GIT_INCOMING"

prepare_deployment_folder

check_prod_backup_latest

# Previous step is to check if the production backup is same as in the sftp server
if [[ $? -eq 0 ]]; then
  echo "Deployment folder is ready at '$OUT_DIR'."
fi

exit $EXIT_SUCCESS
