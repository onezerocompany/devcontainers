#!/bin/bash
# Common Utilities Feature Installation Script
set -e

# Feature options
DEFAULT_SHELL="${DEFAULTSHELL:-zsh}"
INSTALL_STARSHIP="${INSTALLSTARSHIP:-true}"
INSTALL_ZOXIDE="${INSTALLZOXIDE:-true}"
INSTALL_EZA="${INSTALLEZA:-true}"
INSTALL_BAT="${INSTALLBAT:-true}"
INSTALL_WEBDEV_BUNDLE="${WEBDEVBUNDLE:-true}"
INSTALL_NETWORKING_BUNDLE="${NETWORKINGBUNDLE:-true}"
INSTALL_CONTAINERS_BUNDLE="${CONTAINERSBUNDLE:-false}"
INSTALL_UTILITIES_BUNDLE="${UTILITIESBUNDLE:-true}"
CONFIGURE_FOR_ROOT="${CONFIGUREFORROOT:-true}"
INSTALL_COMPLETIONS="${INSTALLCOMPLETIONS:-true}"
INSTALL_MOTD="${INSTALLMOTD:-true}"
INSTALL_SHIMS="${INSTALLSHIMS:-true}"
INSTALL_BUILD_TOOLS="${INSTALLBUILDTOOLS:-true}"
INSTALL_DATABASE_CLIENTS="${INSTALLDATABASECLIENTS:-true}"
INSTALL_GITHUB_CLI="${INSTALLGITHUBCLI:-true}"
INSTALL_KUBERNETES_TOOLS="${INSTALLKUBERNETESTOOLS:-true}"
INSTALL_PODMAN="${INSTALLPODMAN:-true}"
INSTALL_SSH_SERVER="${INSTALLSSHSERVER:-false}"
MOTD_TEXT="${MOTDTEXT:-}"


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

echo "Installing Common Utilities for user: ${USERNAME}"

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

# Make tool scripts executable
find "${SCRIPT_DIR}/tools" -name "*.sh" -type f -exec chmod +x {} \;

# Source function files that contain installation functions
[ -f "${SCRIPT_DIR}/tools/shell/motd.sh" ] && source "${SCRIPT_DIR}/tools/shell/motd.sh"
[ -f "${SCRIPT_DIR}/tools/utils.sh" ] && source "${SCRIPT_DIR}/tools/utils.sh"
[ -f "${SCRIPT_DIR}/tools/mise.sh" ] && source "${SCRIPT_DIR}/tools/mise.sh"

# Source bundle functions
for bundle_script in "${SCRIPT_DIR}"/tools/bundles/*.sh; do
    if [ -f "$bundle_script" ]; then
        source "$bundle_script"
    fi
done

# Install tools based on options
if [ "${INSTALL_STARSHIP}" = "true" ]; then
    "${SCRIPT_DIR}/tools/shell/starship/starship.sh"
fi

if [ "${INSTALL_ZOXIDE}" = "true" ]; then
    "${SCRIPT_DIR}/tools/shell/zoxide.sh"
fi

if [ "${INSTALL_EZA}" = "true" ]; then
    "${SCRIPT_DIR}/tools/shell/eza.sh"
fi

if [ "${INSTALL_BAT}" = "true" ]; then
    "${SCRIPT_DIR}/tools/shell/bat.sh"
fi

# Install tool bundles based on options
if [ "${INSTALL_WEBDEV_BUNDLE}" = "true" ]; then
    install_webdev_bundle "$INSTALL_DATABASE_CLIENTS"
fi

if [ "${INSTALL_NETWORKING_BUNDLE}" = "true" ]; then
    install_networking_bundle "$INSTALL_SSH_SERVER"
fi

if [ "${INSTALL_CONTAINERS_BUNDLE}" = "true" ]; then
    install_containers_bundle "$INSTALL_KUBERNETES_TOOLS" "$INSTALL_PODMAN"
fi

if [ "${INSTALL_UTILITIES_BUNDLE}" = "true" ]; then
    install_utilities_bundle "$INSTALL_BUILD_TOOLS" "$INSTALL_GITHUB_CLI"
fi

# ========================================
# INSTALL SHIM SCRIPTS
# ========================================

if [ "${INSTALL_SHIMS}" = "true" ]; then
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

# Install MOTD if enabled
if [ "${INSTALL_MOTD}" = "true" ] && command -v install_motd >/dev/null 2>&1; then
    install_motd "$USER_HOME" "$MOTD_TEXT"
fi

# Configure shell files with modern tools
echo "🔧 Setting up shell configurations..."
if command -v configure_tools >/dev/null 2>&1; then
    configure_tools "$USERNAME" "$USER_HOME" "$INSTALL_STARSHIP" "$INSTALL_ZOXIDE" "$INSTALL_EZA" "$INSTALL_BAT"
fi

# Setup shell completions
if [ "${INSTALL_COMPLETIONS}" = "true" ] && [ -f "${SCRIPT_DIR}/tools/shell/completions.sh" ]; then
    source "${SCRIPT_DIR}/tools/shell/completions.sh"
    setup_completions_for_user "$USER_HOME" "$USERNAME"
fi

# Setup bundle configurations
if [ "${INSTALL_WEBDEV_BUNDLE}" = "true" ] && [ -f "${SCRIPT_DIR}/tools/bundles/web-dev.sh" ]; then
    source "${SCRIPT_DIR}/tools/bundles/web-dev.sh"
    setup_webdev_for_user "$USER_HOME" "$USERNAME"
fi

if [ "${INSTALL_NETWORKING_BUNDLE}" = "true" ] && [ -f "${SCRIPT_DIR}/tools/bundles/networking.sh" ]; then
    source "${SCRIPT_DIR}/tools/bundles/networking.sh"
    setup_networking_for_user "$USER_HOME" "$USERNAME"
fi

if [ "${INSTALL_CONTAINERS_BUNDLE}" = "true" ] && [ -f "${SCRIPT_DIR}/tools/bundles/containers.sh" ]; then
    source "${SCRIPT_DIR}/tools/bundles/containers.sh"
    setup_containers_for_user "$USER_HOME" "$USERNAME"
fi

if [ "${INSTALL_UTILITIES_BUNDLE}" = "true" ] && [ -f "${SCRIPT_DIR}/tools/bundles/utilities.sh" ]; then
    source "${SCRIPT_DIR}/tools/bundles/utilities.sh"
    setup_utilities_for_user "$USER_HOME" "$USERNAME"
fi

# Also configure root if requested and we're configuring another user
if [ "${CONFIGURE_FOR_ROOT}" = "true" ] && [ "$USERNAME" != "root" ]; then
    echo "  Also creating shell configurations for root..."
    
    # Install MOTD for root if enabled
    if [ "${INSTALL_MOTD}" = "true" ] && command -v install_motd >/dev/null 2>&1; then
        install_motd "/root" "$MOTD_TEXT"
    fi
    
    # Configure shell files with modern tools for root
    if command -v configure_tools >/dev/null 2>&1; then
        configure_tools "root" "/root" "$INSTALL_STARSHIP" "$INSTALL_ZOXIDE" "$INSTALL_EZA" "$INSTALL_BAT"
    fi
    
    # Setup completions for root too
    if [ "${INSTALL_COMPLETIONS}" = "true" ] && [ -f "${SCRIPT_DIR}/tools/shell/completions.sh" ]; then
        setup_completions_for_user "/root" "root"
    fi
    
    # Setup bundle configurations for root
    if [ "${INSTALL_WEBDEV_BUNDLE}" = "true" ] && command -v setup_webdev_for_user >/dev/null 2>&1; then
        setup_webdev_for_user "/root" "root"
    fi
    
    if [ "${INSTALL_NETWORKING_BUNDLE}" = "true" ] && command -v setup_networking_for_user >/dev/null 2>&1; then
        setup_networking_for_user "/root" "root"
    fi
    
    if [ "${INSTALL_CONTAINERS_BUNDLE}" = "true" ] && command -v setup_containers_for_user >/dev/null 2>&1; then
        setup_containers_for_user "/root" "root"
    fi
    
    if [ "${INSTALL_UTILITIES_BUNDLE}" = "true" ] && command -v setup_utilities_for_user >/dev/null 2>&1; then
        setup_utilities_for_user "/root" "root"
    fi
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

echo "✅ Common Utilities installation completed!"