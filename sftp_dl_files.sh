#!/bin/bash

# This script downloads the latest production codes or scripts from a remote SFTP server.
# It will iterate through a directory, and download all files in the directory from the remote SFTP server.

# ----------------------------
# CONFIGURATION
# ----------------------------

# The SFTP connection details
SFTP_USER="leejun"           # Replace with the remote SFTP server username
SFTP_HOST="mywavedevsg1apps1.southeastasia.cloudapp.azure.com"        # Replace with the remote SFTP server hostname or IP address
SFTP_PORT=3310                        # Replace with the port if it's not the default SFTP port (22)

# Remote directory to download files from
REMOTE_DIR="/home/leejun/testsftpdl"    # Replace with the actual path on your SFTP server

# Local directory to save downloaded files
LOCAL_DIR="/Users/slj/WorkOS/Projects/shell-sftp-dl/sample_files/"        # Modify as needed; default is './downloaded_files'
LOCAL_COMPARE_DIR="/Users/slj/WorkOS/Projects/shell-sftp-dl/sample_files_remote"
SSH_KEY="/Users/slj/.ssh/rsa/leejun_rsa"  # Path to your SSH private key for authentication

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
}

# ----------------------------
# SCRIPT LOGIC
# ----------------------------

# Collect all files to sftp download
FILES_TO_DOWNLOAD=()
while IFS= read -r -d '' file; do
  RELATIVE_PATH=${file#$LOCAL_DIR} # Remove the base directory path to get relative paths
  FILES_TO_DOWNLOAD+=("$RELATIVE_PATH")
done < <(find "$LOCAL_DIR" -type f -print0) # Use -print0 for null-delimited file names (safe for special characters)

echo "Comparing following files with remote server:"
for file in "${FILES_TO_DOWNLOAD[@]}"; do
  echo "  - $file"
done

# Use SFTP to batch download all files
sftp_download_files

# Confirm completion
if [[ $? -eq 0 ]]; then
  echo "All files successfully downloaded to: $LOCAL_COMPARE_DIR"
else
  echo "An error occurred during the SFTP transfer."
  exit 1
fi


