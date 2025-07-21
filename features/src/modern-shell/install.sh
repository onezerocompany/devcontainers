#!/bin/bash
# Modern Shell Tools Feature Installation Script
set -e

# Feature options
DEFAULT_SHELL="${DEFAULTSHELL:-zsh}"
INSTALL_STARSHIP="${INSTALLSTARSHIP:-true}"
INSTALL_ZOXIDE="${INSTALLZOXIDE:-true}"
INSTALL_EZA="${INSTALLEZA:-true}"
INSTALL_BAT="${INSTALLBAT:-true}"
CONFIGURE_FOR_ROOT="${CONFIGUREFORROOT:-true}"

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get the non-root user
USERNAME="${_REMOTE_USER:-"automatic"}"
if [ "${USERNAME}" = "auto" ] || [ "${USERNAME}" = "automatic" ]; then
    USERNAME=""
    POSSIBLE_USERS=("zero" "vscode" "node" "codespace" "$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd)")
    for CURRENT_USER in "${POSSIBLE_USERS[@]}"; do
        if id -u "${CURRENT_USER}" > /dev/null 2>&1; then
            USERNAME=${CURRENT_USER}
            break
        fi
    done
    if [ "${USERNAME}" = "" ]; then
        USERNAME=root
    fi
elif [ "${USERNAME}" = "none" ] || [ "${USERNAME}" = "root" ]; then
    USERNAME=root
fi

echo "Installing Modern Shell Tools for user: ${USERNAME}"

# ========================================
# APT PACKAGES
# ========================================

echo "📦 Installing required packages..."
apt-get update
apt-get install -y \
    curl \
    wget \
    git \
    zsh \
    bash \
    ca-certificates \
    gnupg

# ========================================
# MODERN CLI TOOLS INSTALLATION
# ========================================

# Make scripts executable
chmod +x "${SCRIPT_DIR}"/scripts/*.sh

# Install tools based on options
if [ "${INSTALL_STARSHIP}" = "true" ]; then
    "${SCRIPT_DIR}/scripts/install-starship.sh"
fi

if [ "${INSTALL_ZOXIDE}" = "true" ]; then
    "${SCRIPT_DIR}/scripts/install-zoxide.sh"
fi

if [ "${INSTALL_EZA}" = "true" ]; then
    "${SCRIPT_DIR}/scripts/install-eza.sh"
fi

if [ "${INSTALL_BAT}" = "true" ]; then
    "${SCRIPT_DIR}/scripts/install-bat.sh"
fi

# ========================================
# SHELL CONFIGURATION
# ========================================

# Configure shells for the specified user
if [ "$USERNAME" = "root" ]; then
    USER_HOME="/root"
else
    USER_HOME="/home/$USERNAME"
fi

"${SCRIPT_DIR}/scripts/configure-shells.sh" \
    "$USERNAME" \
    "$USER_HOME" \
    "$INSTALL_STARSHIP" \
    "$INSTALL_ZOXIDE" \
    "$INSTALL_EZA" \
    "$INSTALL_BAT"

# Also configure root if requested and we're configuring another user
if [ "${CONFIGURE_FOR_ROOT}" = "true" ] && [ "$USERNAME" != "root" ]; then
    echo "  Also creating shell configurations for root..."
    "${SCRIPT_DIR}/scripts/configure-shells.sh" \
        "root" \
        "/root" \
        "$INSTALL_STARSHIP" \
        "$INSTALL_ZOXIDE" \
        "$INSTALL_EZA" \
        "$INSTALL_BAT"
fi

# ========================================
# SET DEFAULT SHELL
# ========================================

echo "🐚 Setting default shell..."

# Determine shell path
if [ "${DEFAULT_SHELL}" = "zsh" ]; then
    SHELL_PATH="/bin/zsh"
elif [ "${DEFAULT_SHELL}" = "bash" ]; then
    SHELL_PATH="/bin/bash"
else
    echo "Warning: Unknown shell '${DEFAULT_SHELL}', defaulting to zsh"
    SHELL_PATH="/bin/zsh"
fi

# Update user's shell
if [ "$USERNAME" != "root" ]; then
    chsh -s "$SHELL_PATH" "$USERNAME"
fi

# Update root's shell if configured
if [ "${CONFIGURE_FOR_ROOT}" = "true" ]; then
    chsh -s "$SHELL_PATH" root
fi

echo "✅ Modern Shell Tools installation completed!"