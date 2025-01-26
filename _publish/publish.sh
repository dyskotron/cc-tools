#!/bin/bash

# Path to your virtual environment (relative to current directory)
VENV_PATH="./venv"  # Replace with the actual name of your virtual environment folder

# Path to your Python upload script (relative to current directory)
UPLOAD_SCRIPT="./upload_files.py"

# Check if the virtual environment exists
if [ ! -d "$VENV_PATH" ]; then
    echo "Error: Virtual environment not found at $VENV_PATH."
    exit 1
fi

# Activate the virtual environment
source "$VENV_PATH/bin/activate"

# Check if the activation was successful
if [ $? -ne 0 ]; then
    echo "Error: Failed to activate virtual environment."
    exit 1
fi

# Run the upload Python script
python "$UPLOAD_SCRIPT"

# Deactivate the virtual environment
if [ $? -eq 0 ]; then
    echo "Upload script executed successfully."
else
    echo "Error: Upload script encountered an issue."
fi

deactivate
