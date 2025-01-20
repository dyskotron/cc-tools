#!/bin/bash

# Resolve the directory containing this script
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Path to the Python script in the same folder as this script
PYTHON_SCRIPT="$SCRIPT_DIR/magica_parser.py"

# Check if the Python script exists
if [ ! -f "$PYTHON_SCRIPT" ]; then
    osascript -e 'display notification "Python script not found in the same folder as the droplet." with title "Error"'
    exit 1
fi

# Process each file dropped onto the droplet
for INPUT_FILE in "$@"; do
    INPUT_DIR="$(dirname "$INPUT_FILE")"
    INPUT_NAME="$(basename "$INPUT_FILE" .vox)"
    OUTPUT_BINARY="${INPUT_DIR}/${INPUT_NAME}.bin"
    LOG_FILE="${INPUT_DIR}/${INPUT_NAME}.log"

    # Run the Python script
    python3 "$PYTHON_SCRIPT" "$INPUT_FILE" "$OUTPUT_BINARY" > "$LOG_FILE" 2>&1

    # Check if the script succeeded
    if [ $? -eq 0 ]; then
        osascript -e 'display notification "Processing completed successfully!" with title "Magica Parser"'
    else
        osascript -e 'display notification "Processing failed. Check the log file." with title "Magica Parser"'
    fi
done