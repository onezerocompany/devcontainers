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

# Check if we have a specific user to install for
if [ -n "$1" ]; then
    TARGET_USER="$1"
    echo "Installing tools for user: $TARGET_USER"

    if [ "$TARGET_USER" = "root" ]; then
        cd /root && mise use -g $TOOLS -y
    else
        su - "$TARGET_USER" -c "mise use -g $TOOLS -y"
    fi
else
    # Install for root by default
    echo "Installing tools for root user: $TOOLS"
    cd /root && mise use -g $TOOLS -y
fi

# Verify installation
echo "Verifying tool installations..."
mise ls || true

echo "Claude tools installation completed successfully!"
