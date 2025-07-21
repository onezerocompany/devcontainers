#!/bin/bash
# Install container-related tools
set -e

APT_CMD="${APT_CMD:-apt-get}"

echo "  🔧 Installing container tools..."

# Install iptables (required for Docker-in-Docker scenarios)
$APT_CMD install -y iptables
update-alternatives --set iptables /usr/sbin/iptables-legacy