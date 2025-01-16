#!/bin/bash

# Define the source and destination directories
SOURCE_DIR="/Users/matejosanec/IdeaProjects/lua test"
DEST_DIR="/Users/matejosanec/Documents/curseforge/minecraft/Instances/Prominence II RPG_ Hasturian Era/saves/ComputerCraft tests/computercraft/computer/3"

# Check if the source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: Source directory $SOURCE_DIR does not exist."
    exit 1
fi

# Create the destination directory if it does not exist
if [ ! -d "$DEST_DIR" ]; then
    mkdir -p "$DEST_DIR"
fi

# Use rsync to copy all .lua files from the source directory, excluding the _publish folder
rsync -av --exclude="_publish" --include="*/" --include="*.lua" --exclude="*" "$SOURCE_DIR/" "$DEST_DIR"

# Verify the operation and provide feedback
if [ $? -eq 0 ]; then
    echo "Lua files successfully copied from $SOURCE_DIR to $DEST_DIR."
else
    echo "Error occurred while copying Lua files."
    exit 1
fi