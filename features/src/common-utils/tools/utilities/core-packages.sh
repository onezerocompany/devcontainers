#!/bin/bash
# Core system utilities installation
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/utils.sh"

echo "  🔧 Adding core system utilities to package list..."

core_packages="curl wget unzip zip p7zip-full tree less ncdu man-db htop lsof procps strace ca-certificates gnupg lsb-release software-properties-common bash-completion vim"

if is_debian_based; then
    add_pkgs "$core_packages"
fi