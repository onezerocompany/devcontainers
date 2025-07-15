#!/bin/bash
# Unified entrypoint for devcontainer variants
# Handles sandbox initialization and VS Code integration

set -e

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/../../base/scripts/common-utils.sh" ]; then
    source "$SCRIPT_DIR/../../base/scripts/common-utils.sh"
else
    # Define minimal functions if common-utils.sh is not found
    fix_docker_permissions() {
        local docker_socket="/var/run/docker.sock"
        if [ -S "$docker_socket" ]; then
            sudo chmod 666 "$docker_socket" 2>/dev/null || true
        fi
    }
    
    execute_command() {
        if [ $# -eq 0 ]; then
            # No command provided
            if [ -t 0 ]; then
                # Interactive terminal - start shell
                exec zsh -l
            else
                # Non-interactive - keep container running
                exec tail -f /dev/null
            fi
        else
            # Execute provided command
            exec "$@"
        fi
    }
fi

USERNAME="${USERNAME:-zero}"

# Note: Docker daemon is not started automatically in DIND variant
# Users should start it manually or use docker compose with appropriate settings

# Main initialization
echo "🚀 Initializing devcontainer..."

# Fix Docker permissions if needed (for both DIND and socket mount)
if [ -S "/var/run/docker.sock" ] && [ "${USERNAME}" != "root" ]; then
    echo "🐳 Configuring Docker access..."
    fix_docker_permissions
fi

# Initialize sandbox (using shared script from base image)
if [ -x "/usr/local/bin/init-sandbox" ]; then
    /usr/local/bin/init-sandbox
fi

# Signal VS Code that initialization is complete
if [ -n "${VSCODE_IPC_HOOK_CLI}" ] || [ -n "${REMOTE_CONTAINERS}" ]; then
    echo "📋 Devcontainer initialization complete"
    # Add a marker file that VS Code can detect
    touch /tmp/.devcontainer-init-complete
    
    # If this is the initial VS Code terminal, signal to close it
    if [ -n "${VSCODE_DEVCONTAINER_INIT}" ]; then
        echo "🔄 Closing initialization terminal..."
        # Give VS Code time to read the output
        sleep 2
        exit 0
    fi
fi

# Execute the command or start interactive shell
execute_command "$@"