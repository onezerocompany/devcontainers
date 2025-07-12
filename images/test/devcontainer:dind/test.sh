#!/bin/bash

set -e

# Test Docker CLI installation
echo "Testing Docker CLI..."
docker --version

# Test Docker Buildx
echo "Testing Docker Buildx..."
docker buildx version

# Test Docker Compose v2
echo "Testing Docker Compose v2..."
docker compose version

# Test docker-compose v1 compatibility
echo "Testing docker-compose v1 compatibility..."
docker-compose --version

# Test Docker daemon connectivity
echo "Testing Docker daemon connectivity..."
docker ps >/dev/null && echo "Docker daemon is accessible"

# Test moby packages (if applicable)
echo "Testing moby packages..."
if command -v dpkg-query >/dev/null 2>&1; then
    dpkg-query -W moby-cli && echo "moby-cli is installed"
    dpkg-query -W moby-buildx && echo "moby-buildx is installed" || echo "moby-buildx not found (might be using docker-buildx-plugin)"
fi

# Test docker-init.sh script exists
echo "Testing docker-init.sh..."
if [ -f "/usr/local/share/docker-init.sh" ]; then
    echo "docker-init.sh script is present"
else
    echo "ERROR: docker-init.sh script is missing!"
    exit 1
fi

# Test user is in docker group
echo "Testing docker group membership..."
if groups | grep -q docker; then
    echo "User is in docker group"
else
    echo "WARNING: User is not in docker group"
fi

# Test VS Code extensions
echo "Testing VS Code kit..."
if command -v vscode-kit >/dev/null 2>&1; then
    echo "vscode-kit is installed"
else
    echo "WARNING: vscode-kit not found"
fi

echo "All tests passed!"