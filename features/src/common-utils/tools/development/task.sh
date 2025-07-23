#!/bin/bash
# Task runner installation
set -e

# Check if this tool should be installed
if [ "${TASKRUNNER:-false}" != "true" ]; then
    echo "  ⏭️  Skipping task runner installation (disabled)"
    return 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/utils.sh"

echo "  🔧 Installing task runners..."
TASK_VERSION="v3.34.1"
TASK_ARCH="linux_amd64"
if [[ $(uname -m) == "aarch64" ]] || [[ $(uname -m) == "arm64" ]]; then
    TASK_ARCH="linux_arm64"
fi

curl -fsSL "https://github.com/go-task/task/releases/download/${TASK_VERSION}/task_${TASK_ARCH}.tar.gz" | tar -xz -C /tmp
mv /tmp/task /usr/local/bin/task
chmod +x /usr/local/bin/task