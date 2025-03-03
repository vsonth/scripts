#!/bin/bash

# Set the directory to search (default to current directory if not provided)
TARGET_DIR="${1:-.}"
LOG_FILE="deleted_folders.log"

# Check if -d flag is provided for deletion
DELETE_FOLDERS=false
if [[ "$2" == "-d" ]]; then
    DELETE_FOLDERS=true
fi

# Find empty directories and log them
find "$TARGET_DIR" -type d -empty > "$LOG_FILE"

echo "Empty folders found (logged in $LOG_FILE):"
cat "$LOG_FILE"

# If -d flag is provided, delete the folders
if $DELETE_FOLDERS; then
    xargs -d '\n' rmdir < "$LOG_FILE"
    echo "Empty folders in '$TARGET_DIR' have been deleted and logged in $LOG_FILE."
else
    echo "Run with '-d' flag to delete the logged empty folders."
fi
