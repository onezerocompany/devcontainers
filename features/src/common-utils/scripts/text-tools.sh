#!/bin/bash
# Install text processing and utility tools
set -e

echo "  📝 Installing text and utility tools..."

apt-get install -y \
    less \
    ncdu \
    man-db \
    apt-transport-https

echo "  ✓ Text and utility tools installed"