#!/bin/bash
# Database clients installation
set -e

# Check if this tool should be installed
if [ "${DATABASECLIENTS:-true}" != "true" ]; then
    echo "  ⏭️  Skipping database clients installation (disabled)"
    return 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/utils.sh"

echo "  🔧 Adding database clients to package list..."
if is_debian_based; then
    add_pkgs "postgresql-client redis-tools"
fi