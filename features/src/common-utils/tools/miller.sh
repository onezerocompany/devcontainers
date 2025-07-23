#!/bin/bash
# Miller data processing installation
set -e

# Check if this tool should be installed
if [ "${MILLER:-false}" != "true" ]; then
    echo "  ⏭️  Skipping miller installation (disabled)"
    return 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/utils.sh"

echo "  🔧 Adding miller (data processing) to package list..."
if is_debian_based; then
    add_pkgs "miller"
elif command -v brew >/dev/null 2>&1; then
    brew install miller
fi