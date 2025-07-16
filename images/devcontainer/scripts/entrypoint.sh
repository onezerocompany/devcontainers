#!/bin/bash
# Unified entrypoint for devcontainer variants
# Handles sandbox initialization and VS Code integration

set -e

# Source common utilities from base image
source /usr/local/bin/common-utils.sh

USERNAME="${USERNAME:-zero}"

# Start Docker daemon for DIND variant if needed
if [ -f /etc/supervisor/supervisord.conf ] && ! pgrep -x dockerd >/dev/null; then
    echo "🐳 Starting Docker daemon..."
    sudo /usr/bin/supervisord -c /etc/supervisor/supervisord.conf -n >> /dev/null 2>&1 &
    # Wait for Docker to be ready
    while ! docker version >/dev/null 2>&1; do
        sleep 1
    done
    echo "✅ Docker daemon started"
fi

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

# Execute the command or start interactive shell
execute_command "$@"