#!/bin/bash
# Core networking tools installation
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/utils.sh"

echo "  🔧 Adding core networking tools to package list..."

# Core networking packages (essential)
core_networking_packages="iproute2 net-tools iputils-ping"

if is_debian_based; then
    add_pkgs "$core_networking_packages"
fi

echo "  ✓ Core networking tools installed"