#!/bin/bash
# Install network utilities
set -e

echo "  🌐 Installing network tools..."

apt-get install -y \
    openssh-client \
    iproute2 \
    net-tools \
    rsync

echo "  ✓ Network tools installed"