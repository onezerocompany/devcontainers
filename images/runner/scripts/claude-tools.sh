#!/bin/bash
# Install common development tools that Claude frequently uses via mise
# These tools are essential for Claude to work effectively in GitHub Actions

set -e

echo "Installing Claude-friendly development tools via mise..."

export DEBIAN_FRONTEND=noninteractive

# Ensure mise is available
if ! command -v mise >/dev/null 2>&1; then
    echo "Error: mise is not installed"
    exit 1
fi

echo "Mise is available: $(mise --version)"

# Tools to install:
# - gh: GitHub CLI for PR creation, issue management, repo operations
# - yq: YAML processor (complement to jq which is already installed)
# - deno: Modern TypeScript/JavaScript runtime
# - usage: CLI spec tool for better autocomplete
# - python: Python runtime for scripts and tools

TOOLS="gh yq deno usage python"

# Install tools globally for runner user
echo "Installing tools for runner user: $TOOLS"
su - runner -c "mise use -g $TOOLS -y" || {
    echo "Warning: Some tools may have failed to install for runner user"
}

# Also install for root user (for privileged operations)
echo "Installing tools for root user: $TOOLS"
cd /root && mise use -g $TOOLS -y || {
    echo "Warning: Some tools may have failed to install for root user"
}

# Verify installations
echo "Verifying tool installations..."
su - runner -c "mise ls" || true

echo "Claude tools installation completed successfully!"
