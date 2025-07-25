#!/bin/bash
# Entrypoint script for devcontainer base image
set -e

echo "🚀 Initializing devcontainer base image..."

if [ $# -eq 0 ]; then
    if [ -t 0 ]; then
        # Interactive terminal - start user's default shell
        USER_SHELL=$(getent passwd "$(whoami)" | cut -d: -f7)
        if [ -z "$USER_SHELL" ]; then
            echo "Error: Could not determine user shell" >&2
            exit 1
        fi
        exec $USER_SHELL -l
    else
        # Non-interactive mode - keep container running
        exec tail -f /dev/null
    fi
else
    # Execute the provided command
    exec "$@"
fi
