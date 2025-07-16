#!/bin/bash
set -e

echo "🚀 Setting up development environment..."
echo

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

echo
# The MOTD will be displayed when the shell starts
echo "✨ DevContainer is ready!"