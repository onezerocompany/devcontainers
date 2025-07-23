#!/bin/bash
# Dive container image analyzer installation
set -e

# Check if this tool should be installed
if [ "${DIVE:-false}" != "true" ]; then
    echo "  ⏭️  Skipping dive installation (disabled)"
    return 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/utils.sh"

echo "  🔧 Installing dive (container image analyzer)..."
DIVE_VERSION="v0.11.0"
DIVE_ARCH="linux_amd64"
if [[ $(uname -m) == "aarch64" ]] || [[ $(uname -m) == "arm64" ]]; then
    DIVE_ARCH="linux_arm64"
fi

curl -fsSL "https://github.com/wagoodman/dive/releases/download/${DIVE_VERSION}/dive_${DIVE_VERSION}_${DIVE_ARCH}.tar.gz" | tar -xz -C /tmp
mv /tmp/dive /usr/local/bin/dive
chmod +x /usr/local/bin/dive