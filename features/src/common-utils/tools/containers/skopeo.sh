#!/bin/bash
# Skopeo installation
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/utils.sh"

echo "  🔧 Adding skopeo to package list..."
if is_debian_based; then
    add_pkgs "skopeo"
fi