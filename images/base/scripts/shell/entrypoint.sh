#!/bin/bash
# Entrypoint script for devcontainer base image
# Handles container initialization and command execution
set -e

# ========================================
# UTILITY FUNCTIONS
# ========================================

# Execute command with sudo if not already root
sudoIf() {
  if [ "$(id -u)" -ne 0 ]; then
    sudo "$@"
  else
    "$@"
  fi
}

# ========================================
# COMMAND EXECUTION HANDLER
# ========================================

execute_command() {
    # Log execution details for debugging
    echo "[EXECUTE_COMMAND] Args: $@" >> /tmp/entrypoint.log
    echo "[EXECUTE_COMMAND] Interactive terminal: $([ -t 0 ] && echo 'yes' || echo 'no')" >> /tmp/entrypoint.log

    if [ $# -eq 0 ]; then
        # No command provided - determine appropriate action
        if [ -t 0 ]; then
            # Interactive terminal detected - start user's default shell
            USER_SHELL=$(getent passwd $(whoami) | cut -d: -f7)
            echo "[EXECUTE_COMMAND] User shell from passwd: $USER_SHELL" >> /tmp/entrypoint.log
            
            # Validate shell exists
            if [ -z "$USER_SHELL" ]; then
                echo "Error: Could not determine user shell" >&2
                exit 1
            fi
            
            echo "[EXECUTE_COMMAND] Starting login shell: $USER_SHELL" >> /tmp/entrypoint.log
            exec $USER_SHELL -l
        else
            # Non-interactive mode - keep container running
            echo "[EXECUTE_COMMAND] Non-interactive mode - keeping container alive" >> /tmp/entrypoint.log
            exec tail -f /dev/null
        fi
    else
        # Execute the provided command
        echo "[EXECUTE_COMMAND] Executing command: $@" >> /tmp/entrypoint.log
        exec "$@"
    fi
}

# ========================================
# MAIN INITIALIZATION
# ========================================

# Set default username if not provided
USERNAME="${USERNAME:-zero}"

# Container startup message
echo "🚀 Initializing devcontainer base image..."

# Add any additional initialization steps here
# (Future extensions can add custom initialization logic)

echo
echo "✅ Container initialized successfully"

# Execute the main command or start shell
execute_command "$@"
