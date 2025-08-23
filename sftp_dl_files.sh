#!/bin/bash

# This script downloads the latest production codes or scripts from a remote SFTP server.
# It will iterate through a directory, and download all files in the directory from the remote SFTP server.

# ----------------------------
# CONFIGURATION
# ----------------------------

# Exit codes
EXIT_SUCCESS=0
EXIT_UNKNOWN_OPTION=1
EXIT_INVALID_OPTION_VALUE=2
EXIT_SFTP_ERROR=3

# Local directory to save downloaded files
UUID=$(uuidgen)
LOCAL_COMPARE_DIR="/tmp/sftp-$UUID"

# Function: read_options
# Description: Reads and parses command-line options for the script.
read_options() {
  while [[ $# -gt 0 ]]; do
    case $1 in
    --sftp-json | -s)
      SFTP_JSON="$2"
      shift 2
      ;;
    --directory | -d)
      DIRECTORY="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit $EXIT_UNKNOWN_OPTION
      ;;
    esac
  done

  # # Check if mandatory options are provided
  if [[ -z "$SFTP_JSON" || -z "$DIRECTORY" ]]; then
    exit $EXIT_UNKNOWN_OPTION
  fi

  # Display the options
  echo "Options:"
  echo "SFTP JSON: $SFTP_JSON"
  echo "Directory: $DIRECTORY"
  echo "" # Add an empty line for better readability

  # Sanitize the directory
  if [[ ! -d "$DIRECTORY" ]]; then
    echo "Error: Directory '$DIRECTORY' does not exist." >&2
    exit $EXIT_INVALID_OPTION_VALUE
  fi

  # The SFTP connection details
  SFTP_HOST=$(cat "$SFTP_JSON" | jq -r '.host')
  SFTP_PORT=$(cat "$SFTP_JSON" | jq -r '.port')
  SFTP_USER=$(cat "$SFTP_JSON" | jq -r '.user')
  SSH_KEY=$(cat "$SFTP_JSON" | jq -r '.sshKey')
  REMOTE_DIR=$(cat "$SFTP_JSON" | jq -r '.remoteDir')
}

# Function: list_files_to_download
# Description: Collects all files from the specified local directory into a global array.
list_files_to_download() {
  # Find all files and store relative paths in the array
  while IFS= read -r -d '' file; do
    relative_path=${file#$DIRECTORY} # Remove the base directory path
    FILES_TO_DOWNLOAD+=("$relative_path")
  done < <(find "$DIRECTORY" -type f -print0)

  # Print the collected files (optional)
  echo "Comparing the following files with remote server:"
  for file in "${FILES_TO_DOWNLOAD[@]}"; do
    echo "  - $file"
  done

  echo "" # Add an empty line for better readability
}

# Function: sftp_download_files
# Description: Connects to the SFTP server and downloads files from the specified remote directory.
sftp_download_files() {
  echo "Connecting to SFTP server $SFTP_HOST:$SFTP_PORT to download files from $REMOTE_DIR."

  sftp -o IdentityFile="$SSH_KEY" -P "$SFTP_PORT" "$SFTP_USER@$SFTP_HOST" <<EOF
  lcd $LOCAL_COMPARE_DIR
  cd $REMOTE_DIR

  # Iterate through the collected files and download each one
  $(for file in "${FILES_TO_DOWNLOAD[@]}"; do
    local_dir=$(dirname "$file")
    mkdir -p "$LOCAL_COMPARE_DIR/$local_dir"
    echo "get $file $LOCAL_COMPARE_DIR/$local_dir"
  done)

  bye
EOF

  # Confirm sftp completed successfully
  if [[ $? -eq 0 ]]; then
    echo "All files successfully downloaded to: $LOCAL_COMPARE_DIR"
  else
    echo "An error occurred during the SFTP transfer."
    exit $EXIT_SFTP_ERROR
  fi

  echo "" # Add an empty line for better readability
}

# Function: perform_diff
# Description: Compares the local directory with the downloaded directory and reports differences if any.
perform_diff() {
  # Diff local directory with downloaded directory
  diff -r "$DIRECTORY" "$LOCAL_COMPARE_DIR"

  # Check the exit status of diff
  if [[ $? -eq 0 ]]; then
    echo "No differences found between local and remote. 😁"
  else
    echo "DIFFERENCES FOUND between local and remote. 😡"
    echo "Please double check if local files are up to date!"
  fi

  echo "" # Add an empty line for better readability

  # Delete recursively downloaded directory after diff
  echo "Cleaning up temporary directory: $LOCAL_COMPARE_DIR"
  rm -rf "$LOCAL_COMPARE_DIR"
}

# ----------------------------
# SCRIPT LOGIC
# ----------------------------

read_options "$@"

FILES_TO_DOWNLOAD=()
list_files_to_download

sftp_download_files

perform_diff

exit $EXIT_SUCCESS
