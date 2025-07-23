#!/bin/bash
# Git extras installation
set -e

# Check if this tool should be installed
if [ "${GITEXTRAS:-false}" != "true" ]; then
    echo "  ⏭️  Skipping git extras installation (disabled)"
    return 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/utils.sh"

echo "  🔧 Adding git extras to package list..."
if is_debian_based; then
    add_pkgs "git-extras"
elif command -v brew >/dev/null 2>&1; then
    brew install git-extras
fi