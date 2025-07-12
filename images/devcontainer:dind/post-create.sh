#!/bin/bash
set -e

echo "🚀 Setting up development environment..."

# Install mise tools in the workspace
if command -v mise &> /dev/null; then
    echo "📦 Installing development tools with mise..."
    # Suppress TERM warnings by setting a minimal TERM if not set
    if [ -z "$TERM" ]; then
        export TERM=dumb
    fi
    
    # Change to workspace directory and run mise install
    if [ -n "$WORKSPACE_FOLDER" ]; then
        cd "$WORKSPACE_FOLDER"
    elif [ -n "$PWD" ]; then
        cd "$PWD"
    fi
    
    # Run mise install (trust is automatic with MISE_TRUSTED_CONFIG_PATHS="/")
    mise install 2>&1 || true
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

# Clear the terminal for a clean start (only if TERM is properly set)
if [ -n "$TERM" ] && [ "$TERM" != "dumb" ]; then
    clear
fi

# The MOTD will be displayed when the shell starts
echo "✨ DevContainer with Docker-in-Docker is ready!"
echo ""
echo "Opening a new terminal session..."
echo ""

# Small delay to ensure everything is loaded
sleep 1