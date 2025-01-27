#!/bin/bash

# Define the source directory
SOURCE_DIR="/Users/matejosanec/IdeaProjects/cctToolbox"
# Define the parent directory of the destination
DEST_PARENT_DIR="/Users/matejosanec/Documents/curseforge/minecraft/Instances/Prominence II RPG_ Hasturian Era/saves/ComputerCraft tests/computercraft/computer"

# Check if the source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: Source directory $SOURCE_DIR does not exist."
    exit 1
fi

# Create the parent destination directory if it does not exist
if [ ! -d "$DEST_PARENT_DIR" ]; then
    mkdir -p "$DEST_PARENT_DIR"
fi

# Loop through all subdirectories in the destination parent directory
for SUB_DIR in "$DEST_PARENT_DIR"/*/; do
    # Exclude directories starting with '.' or '_'
    BASENAME=$(basename "$SUB_DIR")
    if [[ "$BASENAME" == .* || "$BASENAME" == _* ]]; then
        continue
    fi

    # Define the full destination directory path
    DEST_DIR="$SUB_DIR"

    # Use rsync to copy files excluding those starting with '.' or '_'
    rsync -av --prune-empty-dirs \
        --exclude=".*" --exclude="_*" \
        --exclude="_publish" --include="*/" \
        "$SOURCE_DIR/" "$DEST_DIR/"

    # Verify operation and provide feedback
    if [ $? -eq 0 ]; then
        echo "Files successfully copied from $SOURCE_DIR to $DEST_DIR."
    else
        echo "Error occurred while copying files to $DEST_DIR."
        exit 1
    fi
done