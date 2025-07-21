#!/bin/bash
set -e

# Mise installation and setup script
# This script installs mise and configures it for the user

echo "Setting up mise..."

# Create necessary directories
mkdir -p ~/.local/bin
mkdir -p ~/.cache/mise
mkdir -p ~/.local/share/mise

# Determine architecture
ARCH=$(dpkg --print-architecture)
if [ "$ARCH" = "amd64" ]; then
    ARCH="x64"
elif [ "$ARCH" = "arm64" ]; then
    ARCH="arm64"
fi

# Get latest version
MISE_VERSION=$(curl -s https://api.github.com/repos/jdx/mise/releases/latest | jq -r '.tag_name')
echo "Installing mise ${MISE_VERSION} for ${ARCH}..."

# Download and install mise
curl -fsSL "https://github.com/jdx/mise/releases/download/${MISE_VERSION}/mise-${MISE_VERSION}-linux-${ARCH}" -o ~/.local/bin/mise
chmod +x ~/.local/bin/mise

# Verify installation
~/.local/bin/mise --version

# Install tools using mise configuration (if .mise.toml exists)
if [ -f ~/.mise.toml ]; then
    mise install
fi

echo "Mise setup complete!"
