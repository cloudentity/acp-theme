#!/bin/bash
set -e

# This script checks if the local copy of the given file of this repository
# is different from its origin on the original repository.
# The script exits without error if the local copy is DIFFERENT from the origin.

# Check if an argument is provided
if [ "$#" -ne 1 ]
then
    echo "Usage: $0 <file-path>"
    exit 1
fi

# Check if a given file exist
if [ ! -e "$1" ]
then
    echo "Error: '$1' does not exist."
    exit 1
fi

GITHUB_BRANCH="dev"
FILE_PATH="$1"
RAW_URL="https://raw.githubusercontent.com/cloudentity/acp-theme/$GITHUB_BRANCH/$FILE_PATH"
ORIGINAL_FILE="/tmp/${FILE_PATH//\//_}"

# Download the origin file
if ! curl --silent --output "$ORIGINAL_FILE" "$RAW_URL"
then
    echo "Error: Cannot download the original file."
    exit 1
fi

# Compare the origin file with local version
if cmp --silent "$ORIGINAL_FILE" "$FILE_PATH"; then
    exit 2 # The local file is the same
else
    exit 0 # The local file is different - no error
fi

# Remove downloaded origin file
rm "$ORIGINAL_FILE"
