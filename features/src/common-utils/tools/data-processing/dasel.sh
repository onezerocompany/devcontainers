#!/bin/bash
# Dasel multi-format data processor installation
set -e

# Check if this tool should be installed
if [ "${DASEL:-false}" != "true" ]; then
    echo "  ⏭️  Skipping dasel installation (disabled)"
    return 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/utils.sh"

echo "  🔧 Installing dasel (multi-format data processor)..."
DASEL_VERSION="v2.4.1"
DASEL_ARCH="linux_amd64"
if [[ $(uname -m) == "aarch64" ]] || [[ $(uname -m) == "arm64" ]]; then
    DASEL_ARCH="linux_arm64"
fi

curl -fsSL "https://github.com/TomWright/dasel/releases/download/${DASEL_VERSION}/dasel_${DASEL_ARCH}" -o /usr/local/bin/dasel
chmod +x /usr/local/bin/dasel