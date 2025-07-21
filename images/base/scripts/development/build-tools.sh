#!/bin/bash
# Install additional build tools and libraries
# Note: buildpack-deps includes: gcc, g++, make, autoconf, automake, libtool, patch, file,
#       dpkg-dev, libc6-dev, libssl-dev, zlib1g-dev, and many dev libraries
set -e

APT_CMD="${APT_CMD:-apt-get}"

echo "  🔨 Installing build tools and libraries..."

# Additional build tools beyond buildpack-deps
$APT_CMD install -y \
     cmake \
     libglu1-mesa \
     libgssapi-krb5-2 \
     libicu-dev