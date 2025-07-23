#!/bin/bash
# SSH client installation
set -e

# Check if this tool should be installed
if [ "${SSHCLIENT:-true}" != "true" ]; then
    echo "  ⏭️  Skipping SSH client installation (disabled)"
    return 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/utils.sh"

echo "  🔧 Adding SSH client to package list..."

if is_debian_based; then
    add_pkgs "openssh-client"
fi

echo "  ✓ SSH client installed"