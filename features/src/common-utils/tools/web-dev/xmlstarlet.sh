#!/bin/bash
# XMLStarlet installation
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/utils.sh"

echo "  🔧 Installing XMLStarlet..."
if is_debian_based; then
    apt_get_update_if_needed
    apt-get install -y xmlstarlet
fi