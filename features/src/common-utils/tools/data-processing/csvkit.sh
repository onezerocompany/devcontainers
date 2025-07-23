#!/bin/bash
# CSVKit installation
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/utils.sh"

echo "  🔧 Installing CSV processing tools..."
if command -v pip3 >/dev/null 2>&1; then
    pip3 install csvkit
fi