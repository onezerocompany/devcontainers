#!/bin/bash
# GitHub CLI installation
set -e

# Check if this tool should be installed
if [ "${GITHUBCLI:-false}" != "true" ]; then
    echo "  ⏭️  Skipping GitHub CLI installation (disabled)"
    return 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/utils.sh"

echo "  🔧 Installing GitHub CLI..."
if is_debian_based; then
    # Add GitHub CLI repository
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    apt_get_update_if_needed
    apt-get install -y gh
elif command -v brew >/dev/null 2>&1; then
    brew install gh
fi