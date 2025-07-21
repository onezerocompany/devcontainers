#!/bin/bash
# Common Utilities Feature Installation Script
set -e

# Feature options
INSTALL_NETWORK_TOOLS="${INSTALLNETWORKTOOLS:-true}"
INSTALL_SYSTEM_TOOLS="${INSTALLSYSTEMTOOLS:-true}"
INSTALL_TEXT_TOOLS="${INSTALLTEXTTOOLS:-true}"
INSTALL_BASH_COMPLETION="${INSTALLBASHCOMPLETION:-true}"

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing Common Utilities..."

# ========================================
# APT UPDATE
# ========================================

echo "📦 Updating package lists..."
apt-get update

# ========================================
# UTILITIES INSTALLATION
# ========================================

# Make scripts executable
chmod +x "${SCRIPT_DIR}"/scripts/*.sh

# Install utilities based on options
if [ "${INSTALL_NETWORK_TOOLS}" = "true" ]; then
    "${SCRIPT_DIR}/scripts/install-network-tools.sh"
fi

if [ "${INSTALL_SYSTEM_TOOLS}" = "true" ]; then
    "${SCRIPT_DIR}/scripts/install-system-tools.sh"
fi

if [ "${INSTALL_TEXT_TOOLS}" = "true" ]; then
    "${SCRIPT_DIR}/scripts/install-text-tools.sh"
fi

if [ "${INSTALL_BASH_COMPLETION}" = "true" ]; then
    "${SCRIPT_DIR}/scripts/install-bash-completion.sh"
fi

# ========================================
# INSTALL SHIM SCRIPTS
# ========================================

echo "🔗 Installing shim scripts..."

# Install code shim
cp -f "${SCRIPT_DIR}/bin/code" /usr/local/bin/
chmod +rx /usr/local/bin/code

# Install systemctl shim
cp -f "${SCRIPT_DIR}/bin/systemctl" /usr/local/bin/systemctl
chmod +rx /usr/local/bin/systemctl

# Install devcontainer-info
cp -f "${SCRIPT_DIR}/bin/devcontainer-info" /usr/local/bin/devcontainer-info
chmod +rx /usr/local/bin/devcontainer-info

echo "✅ Common Utilities installation completed!"