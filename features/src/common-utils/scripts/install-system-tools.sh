#!/bin/bash
# Install system monitoring and debugging tools
set -e

echo "  📊 Installing system tools..."

apt-get install -y \
    htop \
    lsof \
    procps \
    strace

echo "  ✓ System tools installed"