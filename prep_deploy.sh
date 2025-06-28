#!/bin/bash

################################################################################################################
#
# This script accept 4 options:
# 1. --source: The source directory to copy files from. Must be a Git repository. Must be an absolute path.
# 2. --out: The output directory to copy files to. Must be an absolute path.
# 3. --git-target: The target branch for the Git repository
# 4. --git-incoming: The incoming branch for the Git repository
#
# Usage: ./prep_deploy.sh --source /path/to/source/ --out /path/to/out/ --git-target target_branch --git-incoming incoming_branch
#
# The script will first check if the source directory is a Git repository.
# If it is, it will Git list the files changed between the target and incoming
# branches. It will write the list of files to a file called
# "changed_files.txt" in the /path/to/out/_backup/ directory.
#
################################################################################################################
