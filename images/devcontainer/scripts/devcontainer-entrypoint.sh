#!/bin/bash
# Devcontainer-specific entrypoint
# Handles sandbox initialization and VS Code integration without duplicating base logic

set -e

# Source common utilities from base image
source /usr/local/bin/common-utils.sh

USERNAME="${USERNAME:-zero}"

# Main initialization
echo "🚀 Initializing devcontainer..."
echo

# Initialize sandbox (using shared script from base image)
if [ -x "/usr/local/bin/init-sandbox" ]; then
    /usr/local/bin/init-sandbox
    echo
fi

# Initialize DNS filter (if enabled)
if [ -x "/usr/local/bin/init-dns-filter" ]; then
    /usr/local/bin/init-dns-filter
    echo
fi

# Ensure mise tools are available in PATH for shell configuration
if [ -f "$HOME/.local/bin/mise" ]; then
    echo "  🔧 Configuring development tools..."
    export PATH="$HOME/.local/bin:$PATH"
    eval "$($HOME/.local/bin/mise activate bash --shims)"
    echo "    ✓ Development tools configured"
    echo
fi

# Signal that initialization is complete
echo "✅ Devcontainer initialization complete"
# Add a marker file that VS Code can detect
touch /tmp/.devcontainer-init-complete

# VS Code specific behavior
if [ -n "${VSCODE_IPC_HOOK_CLI}" ] || [ -n "${REMOTE_CONTAINERS}" ]; then
    # If this is the initial VS Code terminal, signal to close it
    if [ -n "${VSCODE_DEVCONTAINER_INIT}" ]; then
        echo
        echo "🔄 Closing initialization terminal..."
        # Give VS Code time to read the output
        sleep 2
        exit 0
    fi
fi

# Run the base entrypoint script with all arguments
# This handles Docker initialization and command execution
exec /usr/local/bin/entrypoint.sh "$@"