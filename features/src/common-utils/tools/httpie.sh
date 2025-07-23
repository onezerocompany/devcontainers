#!/bin/bash
# HTTPie installation
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/utils.sh"

# Check if HTTPie should be installed (individual option or web dev bundle)
if [ "${HTTPIE:-true}" = "true" ]; then
    echo "  🔧 Adding HTTPie to package list..."
    if is_debian_based; then
        add_pkgs "httpie"
    fi
else
    echo "  ⏭️  Skipping HTTPie installation (disabled)"
fi