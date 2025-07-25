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

# Create marker file to indicate initialization is complete
touch "${MISE_INITIALIZED_MARKER}"

echo "mise initialization complete!"