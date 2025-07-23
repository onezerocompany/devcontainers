#!/bin/bash
# Buildah installation
set -e

# Check if this tool should be installed
if [ "${BUILDAH:-false}" != "true" ]; then
    echo "  ⏭️  Skipping buildah installation (disabled)"
    return 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/utils.sh"

echo "  🔧 Adding buildah to package list..."
if is_debian_based; then
    add_pkgs "buildah"
fi