#!/bin/bash
# Apache2 utilities installation
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/utils.sh"

echo "  🔧 Installing Apache2 utilities..."
if is_debian_based; then
    apt_get_update_if_needed
    apt-get install -y apache2-utils
fi