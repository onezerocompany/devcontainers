#!/bin/bash
# File transfer tools installation
set -e

# Check if this tool should be installed
if [ "${FILETRANSFER:-true}" != "true" ]; then
    echo "  ⏭️  Skipping file transfer tools installation (disabled)"
    return 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/utils.sh"

echo "  🔧 Adding file transfer tools to package list..."

# File transfer tools
transfer_packages="rsync wget curl"

if is_debian_based; then
    add_pkgs "$transfer_packages"
fi

echo "  ✓ File transfer tools installed (rsync, wget, curl)"