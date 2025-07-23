#!/bin/bash
# Nmap network scanner installation
set -e

# Check if this tool should be installed
if [ "${NMAP:-true}" != "true" ]; then
    echo "  ⏭️  Skipping nmap installation (disabled)"
    return 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/utils.sh"

echo "  🔧 Adding nmap (network scanner) to package list..."

if is_debian_based; then
    add_pkgs "nmap"
fi

echo "  ✓ nmap installed"