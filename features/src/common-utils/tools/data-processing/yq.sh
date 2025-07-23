#!/bin/bash
# yq YAML processor installation
set -e

# Check if this tool should be installed
if [ "${YQ:-true}" != "true" ]; then
    echo "  ⏭️  Skipping yq installation (disabled)"
    return 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/utils.sh"

echo "  🔧 Installing yq (YAML processor)..."
YQ_VERSION="v4.40.5"
YQ_ARCH="linux_amd64"
if [[ $(uname -m) == "aarch64" ]] || [[ $(uname -m) == "arm64" ]]; then
    YQ_ARCH="linux_arm64"
fi

curl -fsSL "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_${YQ_ARCH}" -o /usr/local/bin/yq
chmod +x /usr/local/bin/yq