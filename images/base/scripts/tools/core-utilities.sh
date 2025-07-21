#!/bin/bash
# Install core utilities and editors
# Note: buildpack-deps already includes: curl, wget, git, xz-utils, ca-certificates, gnupg, unzip
set -e

APT_CMD="${APT_CMD:-apt-get}"

echo "  📦 Installing essential tools..."

# Basic utilities and editors
# We only need to install editors and additional utilities
$APT_CMD install -y \
    sudo \
    nano \
    vim \
    zip \
    jq \
    lsb-release