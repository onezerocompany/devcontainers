#!/bin/bash
# Ripgrep (modern grep) installation
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/utils.sh"

# Check if ripgrep should be installed (individual option or shell bundle)
if [ "${RIPGREP:-true}" = "true" ]; then
    echo "  🔧 Installing ripgrep (modern grep)..."
    if command -v cargo >/dev/null 2>&1; then
        cargo install ripgrep
    elif is_debian_based; then
        apt_get_update_if_needed
        apt-get install -y ripgrep
    elif command -v brew >/dev/null 2>&1; then
        brew install ripgrep
    fi
else
    echo "  ⏭️  Skipping ripgrep installation (disabled)"
fi