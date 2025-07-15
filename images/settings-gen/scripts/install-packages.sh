#!/bin/sh
set -e

echo "Installing packages for settings generator..."

apk add --no-cache \
    nodejs \
    npm \
    jq

npm install -g @devcontainers/cli

echo "Package installation complete."