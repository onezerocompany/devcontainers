#!/bin/bash
# GitLab CLI installation
set -e

# Check if this tool should be installed
if [ "${GITLABCLI:-false}" != "true" ]; then
    echo "  ⏭️  Skipping GitLab CLI installation (disabled)"
    return 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/utils.sh"

echo "  🔧 Installing GitLab CLI..."
if is_debian_based; then
    GLAB_VERSION="v1.36.0"
    GLAB_ARCH="Linux_x86_64"
    if [[ $(uname -m) == "aarch64" ]] || [[ $(uname -m) == "arm64" ]]; then
        GLAB_ARCH="Linux_arm64"
    fi
    
    curl -fsSL "https://gitlab.com/gitlab-org/cli/-/releases/${GLAB_VERSION}/downloads/glab_${GLAB_VERSION}_${GLAB_ARCH}.tar.gz" | tar -xz -C /tmp
    mv "/tmp/bin/glab" /usr/local/bin/glab
    chmod +x /usr/local/bin/glab
elif command -v brew >/dev/null 2>&1; then
    brew install glab
fi