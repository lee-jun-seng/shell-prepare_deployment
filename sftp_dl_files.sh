#!/bin/bash

# This script downloads the latest production codes or scripts from a remote SFTP server.
# It will iterate through a directory, and download all files in the directory from the remote SFTP server.

# ----------------------------
# CONFIGURATION
# ----------------------------

# The SFTP connection details
REMOTE_USER="leejun"           # Replace with the remote SFTP server username
REMOTE_HOST="mywavedevsg1apps1.southeastasia.cloudapp.azure.com"        # Replace with the remote SFTP server hostname or IP address
REMOTE_PORT=3310                        # Replace with the port if it's not the default SFTP port (22)

# Remote directory to download files from
REMOTE_DIR="/home/leejun/testsftpdl"    # Replace with the actual path on your SFTP server

# Local directory to save downloaded files
LOCAL_DIR="./downloaded_files"        # Modify as needed; default is './downloaded_files'
SSH_KEY="/Users/slj/.ssh/rsa/leejun_rsa"  # Path to your SSH private key for authentication

# ----------------------------
# SCRIPT LOGIC
# ----------------------------

# Check if the local directory exists, if not, create it
if [[ ! -d "$LOCAL_DIR" ]]; then
  echo "Creating local directory: $LOCAL_DIR"
  mkdir -p "$LOCAL_DIR"
fi

# Use SFTP to batch download all files
echo "Connecting to SFTP server $REMOTE_HOST to download files from $REMOTE_DIR."

# Use a "here document" to define the SFTP commands
sftp -o IdentityFile="$SSH_KEY" -P "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" <<EOF
lcd $LOCAL_DIR
cd $REMOTE_DIR
mget *
bye
EOF

# Confirm completion
if [[ $? -eq 0 ]]; then
  echo "All files successfully downloaded to: $LOCAL_DIR"
else
  echo "An error occurred during the SFTP transfer."
  exit 1
fi


