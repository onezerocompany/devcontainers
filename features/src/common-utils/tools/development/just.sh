#!/bin/bash
# Just command runner installation
set -e

# Check if this tool should be installed
if [ "${JUSTRUNNER:-false}" != "true" ]; then
    echo "  ⏭️  Skipping just command runner installation (disabled)"
    return 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/utils.sh"

echo "  🔧 Installing just command runner..."
JUST_VERSION="1.16.0"
JUST_ARCH="x86_64-unknown-linux-musl"
if [[ $(uname -m) == "aarch64" ]] || [[ $(uname -m) == "arm64" ]]; then
    JUST_ARCH="aarch64-unknown-linux-musl"
fi

curl -fsSL "https://github.com/casey/just/releases/download/${JUST_VERSION}/just-${JUST_VERSION}-${JUST_ARCH}.tar.gz" | tar -xz -C /tmp
mv /tmp/just /usr/local/bin/just
chmod +x /usr/local/bin/just