#!/bin/bash
# yj YAML/JSON/TOML converter installation
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/utils.sh"

echo "  🔧 Installing yj (YAML/JSON/TOML converter)..."
YJ_VERSION="v5.1.0"
YJ_ARCH="linux_amd64"
if [[ $(uname -m) == "aarch64" ]] || [[ $(uname -m) == "arm64" ]]; then
    YJ_ARCH="linux_arm64"
fi

curl -fsSL "https://github.com/sclevine/yj/releases/download/${YJ_VERSION}/yj-${YJ_ARCH}" -o /usr/local/bin/yj
chmod +x /usr/local/bin/yj