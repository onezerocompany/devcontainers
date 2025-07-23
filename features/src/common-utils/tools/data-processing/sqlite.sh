#!/bin/bash
# SQLite installation
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/utils.sh"

echo "  🔧 Installing sqlite3..."
if is_debian_based; then
    apt_get_update_if_needed
    apt-get install -y sqlite3
elif command -v brew >/dev/null 2>&1; then
    brew install sqlite
fi