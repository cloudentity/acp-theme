#!/bin/bash
set -e

# This script checks if the local copy of the given file of this repository
# is different from its origin on the original repository.
# The script exits without error if the local copy is DIFFERENT from the origin.

# Check if arguments are provided
if [ "$#" -ne 2 ]
then
    echo "Usage: $0 <origin-revision> <file-path>"
    exit 1
fi

# Check if a given file exist
if [ ! -e "$2" ]
then
    echo "Error: file '$2' does not exist."
    exit 1
fi

GIT_REV="$1"
FILE_PATH="$2"
RAW_URL="https://raw.githubusercontent.com/cloudentity/acp-theme/$GIT_REV/$FILE_PATH"
ORIGINAL_FILE="/tmp/${FILE_PATH//\//_}"

# Download the origin file
if ! curl --silent --fail --output "$ORIGINAL_FILE" "$RAW_URL"
then
    echo "Error: Cannot download the original file: $RAW_URL"
    exit 1
fi

# Compare the origin file with local version
if cmp --silent "$ORIGINAL_FILE" "$FILE_PATH"; then
    exit 2 # The local file is the same
else
    exit 0 # The local file is different - standard exit
fi

# Remove downloaded origin file
rm "$ORIGINAL_FILE"
