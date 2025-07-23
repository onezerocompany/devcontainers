#!/bin/bash
# HTTPStat installation
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/utils.sh"

echo "  🔧 Installing httpstat..."
HTTPSTAT_URL="https://raw.githubusercontent.com/reorx/httpstat/master/httpstat.py"
if curl -fsSL "$HTTPSTAT_URL" -o /usr/local/bin/httpstat; then
    chmod +x /usr/local/bin/httpstat
    echo "    ✓ httpstat installed successfully"
else
    echo "    ⚠️  Failed to download httpstat, skipping"
    rm -f /usr/local/bin/httpstat
fi