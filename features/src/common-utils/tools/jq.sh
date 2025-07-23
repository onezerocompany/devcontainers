#!/bin/bash
# jq JSON processor installation
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/utils.sh"

# Check if jq should be installed (individual option or data processing bundle)
if [ "${JQ:-true}" = "true" ]; then
    echo "  🔧 Adding jq (JSON processor) to package list..."
    if is_debian_based; then
        add_pkgs "jq"
        echo "  ✅ jq added to installation list"
    elif command -v brew >/dev/null 2>&1; then
        if brew install jq; then
            echo "  ✅ jq installed successfully via brew"
        else
            echo "  ❌ Failed to install jq via brew"
            exit 1
        fi
    else
        echo "  ⚠️ No supported package manager found for jq installation"
        exit 1
    fi
else
    echo "  ⏭️  Skipping jq installation (disabled)"
fi