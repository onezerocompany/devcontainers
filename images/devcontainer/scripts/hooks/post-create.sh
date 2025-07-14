#!/bin/bash
set -e

echo "🚀 Setting up development environment..."

# Install project-specific mise tools if .mise.toml exists
if command -v mise &> /dev/null && [ -f ".mise.toml" ]; then
    echo "📦 Installing project-specific tools from .mise.toml..."
    # Suppress TERM warnings by setting a minimal TERM if not set
    if [ -z "$TERM" ]; then
        export TERM=dumb
    fi
    mise trust --all 2>&1 || true
    mise install --yes 2>&1 || true
    echo "✅ Project tools installed"
elif [ -f ".mise.toml" ]; then
    echo "⚠️  mise not found, skipping project tool installation"
fi

# Clear the terminal for a clean start (only if TERM is properly set)
if [ -n "$TERM" ] && [ "$TERM" != "dumb" ]; then
    clear
fi

# The MOTD will be displayed when the shell starts
echo "✨ DevContainer is ready!"
echo ""
echo "Opening a new terminal session..."
echo ""

# Small delay to ensure everything is loaded
sleep 1