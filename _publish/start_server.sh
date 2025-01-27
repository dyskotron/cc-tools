#!/bin/bash

# Define the path to the Python server script
SERVER_SCRIPT="/Users/matejosanec/IdeaProjects/cctToolbox/_publish/http_server.py"

# Define the name of the Python interpreter
PYTHON_BIN="python3"

# Check if the server is already running
SERVER_PID=$(pgrep -f "$SERVER_SCRIPT")

if [ -n "$SERVER_PID" ]; then
    echo "Server is already running with PID $SERVER_PID. Stopping it now..."
    kill "$SERVER_PID"

    if [ $? -eq 0 ]; then
        echo "Successfully stopped the running server."
    else
        echo "Failed to stop the running server. Exiting."
        exit 1
    fi
else
    echo "No existing server is running."
fi

# Start the server in the foreground
echo "Starting the server..."
exec $PYTHON_BIN "$SERVER_SCRIPT"