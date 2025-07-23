#!/bin/bash
# Build essentials installation
set -e

# Check if this tool should be installed
if [ "${BUILDESSENTIALS:-false}" != "true" ]; then
    echo "  ⏭️  Skipping build essentials installation (disabled)"
    return 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/utils.sh"

echo "  🔧 Adding build essentials to package list..."
if is_debian_based; then
    add_pkgs "build-essential cmake pkg-config"
fi