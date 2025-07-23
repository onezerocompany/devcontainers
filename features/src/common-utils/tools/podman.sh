#!/bin/bash
# Podman installation
set -e

# Check if this tool should be installed
if [ "${PODMAN:-false}" != "true" ]; then
    echo "  ⏭️  Skipping podman installation (disabled)"
    return 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/utils.sh"

echo "  🔧 Adding podman to package list..."
if is_debian_based; then
    add_pkgs "podman"
fi