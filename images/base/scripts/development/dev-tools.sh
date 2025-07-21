#!/bin/bash
# Install development tools
# Note: buildpack-deps already includes: libcurl4-openssl-dev, libxml2-dev, gnupg
set -e

APT_CMD="${APT_CMD:-apt-get}"

echo "  🛠️ Installing development tools..."

# Additional development utilities
# libsqlite3-0 is the runtime library (buildpack-deps has libsqlite3-dev)
$APT_CMD install -y \
     skopeo \
     libedit2 \
     libsqlite3-0 \
     libz3-dev \
     tzdata \
     gnome-keyring \
     python3-minimal \
     pkg-config \
     binutils