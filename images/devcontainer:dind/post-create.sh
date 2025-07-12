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

# Verify Docker is accessible
if command -v docker &> /dev/null; then
    echo "🐳 Verifying Docker installation..."
    docker --version
    echo "✅ Docker is ready"
else
    echo "⚠️  Docker not found"
fi

# Clear the terminal for a clean start
clear

# The MOTD will be displayed when the shell starts
echo "✨ DevContainer with Docker-in-Docker is ready!"
echo ""
echo "Opening a new terminal session..."
echo ""

# Small delay to ensure everything is loaded
sleep 1