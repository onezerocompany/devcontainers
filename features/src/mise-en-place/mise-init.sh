#!/usr/bin/env bash
set -e

# Check if mise has been initialized by looking for a marker file
MISE_INITIALIZED_MARKER="${HOME}/.local/share/mise/.initialized"

if [ -f "${MISE_INITIALIZED_MARKER}" ]; then
    exit 0
fi

echo "Initializing mise directories..."

# Ensure mise directories exist with correct permissions
mkdir -p "${HOME}/.cache/mise"
mkdir -p "${HOME}/.local/share/mise"
mkdir -p "${HOME}/.config/mise"

# Auto-trust directories if enabled
if [ "${MISE_AUTO_TRUST}" = "true" ]; then
    # Auto-trust the workspace directory
    if [ -n "${WORKSPACE_DIR}" ]; then
        echo "Auto-trusting workspace directory: ${WORKSPACE_DIR}"
        mise trust "${WORKSPACE_DIR}" 2>/dev/null || true
    elif [ -d "/workspaces" ]; then
        # Common devcontainer workspace location
        echo "Auto-trusting /workspaces directory"
        mise trust "/workspaces" 2>/dev/null || true
    fi

    # Also trust the home directory if it has a .mise.toml
    if [ -f "${HOME}/.mise.toml" ]; then
        echo "Auto-trusting home directory: ${HOME}"
        mise trust "${HOME}" 2>/dev/null || true
    fi
fi

# Create marker file to indicate initialization is complete
touch "${MISE_INITIALIZED_MARKER}"

echo "mise initialization complete!"