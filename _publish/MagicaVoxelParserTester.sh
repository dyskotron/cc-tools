#!/bin/bash

# Resolve the directory containing this script
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Path to the Python scripts in the same folder as this script
PARSER_SCRIPT="$SCRIPT_DIR/magica_parser.py"
VERIFIER_SCRIPT="$SCRIPT_DIR/magica_verifier.py"

# Directory containing the hardcoded input files
INPUT_DIR="$HOME/IdeaProjects/cctToolbox/vox_data"

# Hardcoded input and output files
INPUT_FILE="${INPUT_DIR}/Building_only04.vox"
OUTPUT_BINARY="${INPUT_DIR}/Building_only04.dat"  # The exact same output file is used for verification

# Check if the parser script exists
if [ ! -f "$PARSER_SCRIPT" ]; then
    echo "Error: Parser script not found in the same folder as this script."
    exit 1
fi

# Check if the verifier script exists
if [ ! -f "$VERIFIER_SCRIPT" ]; then
    echo "Error: Verifier script not found in the same folder as this script."
    exit 1
fi

# Check if the input file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input file not found."
    exit 1
fi

# Run the parser script
echo "Running parser on $INPUT_FILE..."
python3 "$PARSER_SCRIPT" "$INPUT_FILE" "$OUTPUT_BINARY"

# Check if parsing succeeded
if [ $? -eq 0 ]; then
    echo "Parsing completed successfully!"

    # Debugging: Ensure the output file exists before verification
    if [ -f "$OUTPUT_BINARY" ]; then
        echo "Verifying output file $OUTPUT_BINARY..."
        python3 "$VERIFIER_SCRIPT" "$OUTPUT_BINARY"

        if [ $? -eq 0 ]; then
            echo "Verification completed successfully!"
        else
            echo "Verification failed."
        fi
    else
        echo "Error: Output file was not created! Cannot proceed with verification."
        exit 1
    fi
else
    echo "Parsing failed."
fi
