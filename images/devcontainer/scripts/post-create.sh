#!/bin/bash
set -e

echo "🚀 Setting up development environment..."
echo

source /usr/local/bin/common-utils.sh

# Install project-specific mise tools if .mise.toml exists
if command -v mise &> /dev/null && [ -f ".mise.toml" ]; then
    echo "  📦 Installing project-specific tools..."
    # Suppress TERM warnings by setting a minimal TERM if not set
    if [ -z "$TERM" ]; then
        export TERM=dumb
    fi
    mise trust --all 2>&1 || true
    mise install --yes 2>&1 || true
    echo "    ✓ Project tools installed"
elif [ -f ".mise.toml" ]; then
    echo "  ⚠️  Warning: mise not found, skipping project tool installation"
fi

# Detect JavaScript runtime and install packages
install_js_dependencies

# Initialize sandbox (using shared script from base image)
if [ -x "/usr/local/bin/init-sandbox" ]; then
    echo "  🛠️ Initializing sandbox environment..."
    /usr/local/bin/init-sandbox
    echo
fi

echo
# The MOTD will be displayed when the shell starts
echo "✨ DevContainer is ready!"