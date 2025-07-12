#!/bin/bash
set -e

echo "🚀 Setting up development environment..."

# Trust and install mise tools
if command -v mise &> /dev/null; then
    echo "📦 Installing development tools with mise..."
    mise trust --all 2>/dev/null || true
    mise install --yes 2>/dev/null || true
    echo "✅ Development tools installed"
else
    echo "⚠️  mise not found, skipping tool installation"
fi

# Clear the terminal for a clean start (only if TERM is set)
if [ -n "$TERM" ]; then
    clear
fi

# The MOTD will be displayed when the shell starts
echo "✨ DevContainer is ready!"
echo ""
echo "Opening a new terminal session..."
echo ""

# Small delay to ensure everything is loaded
sleep 1