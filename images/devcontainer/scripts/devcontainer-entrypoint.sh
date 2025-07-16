#!/bin/bash
# Devcontainer-specific entrypoint
# Handles sandbox initialization and VS Code integration without duplicating base logic

set -e

# Source common utilities from base image
source /usr/local/bin/common-utils.sh

USERNAME="${USERNAME:-zero}"

# Main initialization
echo "=== Devcontainer Initialization ==="

# Initialize sandbox (using shared script from base image)
if [ -x "/usr/local/bin/init-sandbox" ]; then
    /usr/local/bin/init-sandbox
fi

# Ensure mise tools are available in PATH for shell configuration
if [ -f "$HOME/.local/bin/mise" ]; then
    export PATH="$HOME/.local/bin:$PATH"
    eval "$($HOME/.local/bin/mise activate bash --shims)"
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

# Run the base entrypoint script with all arguments
# This handles Docker initialization and command execution
exec /usr/local/bin/entrypoint.sh "$@"