#!/bin/bash
# Crane container registry tool installation
set -e

# Check if this tool should be installed
if [ "${CRANE:-false}" != "true" ]; then
    echo "  ⏭️  Skipping crane installation (disabled)"
    return 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/utils.sh"

echo "  🔧 Installing crane (container registry tool)..."
CRANE_VERSION="v0.17.0"
CRANE_ARCH="Linux_x86_64"
if [[ $(uname -m) == "aarch64" ]] || [[ $(uname -m) == "arm64" ]]; then
    CRANE_ARCH="Linux_arm64"
fi

curl -fsSL "https://github.com/google/go-containerregistry/releases/download/${CRANE_VERSION}/go-containerregistry_${CRANE_ARCH}.tar.gz" | tar -xz -C /tmp
mv /tmp/crane /usr/local/bin/crane
chmod +x /usr/local/bin/crane