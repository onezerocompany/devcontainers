#!/bin/bash
# Common Utilities Feature Installation Script
set -e

# Ensure non-interactive mode for apt
export DEBIAN_FRONTEND=noninteractive

# Feature options
DEFAULT_SHELL="${DEFAULTSHELL:-zsh}"
INSTALL_STARSHIP="${STARSHIP:-true}"
INSTALL_ZOXIDE="${ZOXIDE:-true}"
INSTALL_EZA="${EZA:-true}"
INSTALL_BAT="${BAT:-true}"
INSTALL_ZSH="${ZSH:-true}"
INSTALL_WEBDEV_BUNDLE="${WEBDEV:-true}"
INSTALL_NETWORKING_BUNDLE="${NETWORKING:-true}"
INSTALL_KUBERNETES_BUNDLE="${KUBERNETES:-false}"
INSTALL_UTILITIES_BUNDLE="${UTILITIES:-true}"
CONFIGURE_FOR_ROOT="${CONFIGUREFORROOT:-true}"
INSTALL_COMPLETIONS="${COMPLETIONS:-true}"
INSTALL_MOTD="${MOTD:-true}"
MOTD_LOGO="${MOTDLOGO:-onezero}"
MOTD_INSTRUCTIONS="${MOTDINSTRUCTIONS:-}"
MOTD_NOTICE="${MOTDNOTICE:-}"
INSTALL_SHIMS="${SHIMS:-true}"
INSTALL_BUILD_TOOLS="${BUILDTOOLS:-true}"
INSTALL_DATABASE_CLIENTS="${DATABASECLIENTS:-true}"
INSTALL_GITHUB_CLI="${GITHUBCLI:-true}"


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

# Base packages (always install)
BASE_PACKAGES="curl wget git bash ca-certificates gnupg"

# Add zsh to packages if enabled
if [ "${INSTALL_ZSH}" = "true" ]; then
    BASE_PACKAGES="$BASE_PACKAGES zsh"
fi

apt-get install -y $BASE_PACKAGES

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
    install_networking_bundle
fi

if [ "${INSTALL_KUBERNETES_BUNDLE}" = "true" ]; then
    install_kubernetes_bundle
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
    install_motd "$USER_HOME" "$MOTD_LOGO" "$MOTD_INSTRUCTIONS" "$MOTD_NOTICE"
fi

# Configure shell files with modern tools
echo "🔧 Setting up shell configurations..."
if command -v configure_tools >/dev/null 2>&1; then
    configure_tools "$USERNAME" "$USER_HOME" "$INSTALL_STARSHIP" "$INSTALL_ZOXIDE" "$INSTALL_EZA" "$INSTALL_BAT" "$INSTALL_MOTD"
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


if [ "${INSTALL_KUBERNETES_BUNDLE}" = "true" ] && [ -f "${SCRIPT_DIR}/tools/bundles/kubernetes.sh" ]; then
    source "${SCRIPT_DIR}/tools/bundles/kubernetes.sh"
    setup_kubernetes_for_user "$USER_HOME" "$USERNAME"
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
        install_motd "/root" "$MOTD_LOGO" "$MOTD_INSTRUCTIONS" "$MOTD_NOTICE"
    fi
    
    # Configure shell files with modern tools for root
    if command -v configure_tools >/dev/null 2>&1; then
        configure_tools "root" "/root" "$INSTALL_STARSHIP" "$INSTALL_ZOXIDE" "$INSTALL_EZA" "$INSTALL_BAT" "$INSTALL_MOTD"
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
    
    
    if [ "${INSTALL_KUBERNETES_BUNDLE}" = "true" ] && command -v setup_kubernetes_for_user >/dev/null 2>&1; then
        setup_kubernetes_for_user "/root" "root"
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
if [ "${DEFAULT_SHELL}" = "zsh" ] && [ "${INSTALL_ZSH}" = "true" ]; then
    SHELL_PATH="/bin/zsh"
elif [ "${DEFAULT_SHELL}" = "zsh" ] && [ "${INSTALL_ZSH}" = "false" ]; then
    echo "Warning: defaultShell is set to 'zsh' but zsh installation is disabled, falling back to bash"
    SHELL_PATH="/bin/bash"
elif [ "${DEFAULT_SHELL}" = "bash" ]; then
    SHELL_PATH="/bin/bash"
else
    echo "Warning: Unknown shell '${DEFAULT_SHELL}', defaulting to bash"
    SHELL_PATH="/bin/bash"
fi

# Update user's shell
if [ "$USERNAME" != "root" ]; then
    chsh -s "$SHELL_PATH" "$USERNAME"
fi

# Update root's shell if configured
if [ "${CONFIGURE_FOR_ROOT}" = "true" ]; then
    chsh -s "$SHELL_PATH" root
fi

# ========================================
# INSTALLATION VALIDATION
# ========================================

echo "🔍 Validating installation..."

# Check if requested tools were successfully installed
validation_failed=false

if [ "${INSTALL_STARSHIP}" = "true" ]; then
    if command -v starship >/dev/null 2>&1; then
        echo "  ✓ Starship installed and available"
    else
        echo "  ❌ Starship was requested but not found in PATH"
        validation_failed=true
    fi
fi

if [ "${INSTALL_ZOXIDE}" = "true" ]; then
    if command -v zoxide >/dev/null 2>&1; then
        echo "  ✓ Zoxide installed and available"
    else
        echo "  ❌ Zoxide was requested but not found in PATH"
        validation_failed=true
    fi
fi

if [ "${INSTALL_EZA}" = "true" ]; then
    if command -v eza >/dev/null 2>&1; then
        echo "  ✓ Eza installed and available"
    else
        echo "  ❌ Eza was requested but not found in PATH"
        validation_failed=true
    fi
fi

if [ "${INSTALL_BAT}" = "true" ]; then
    if command -v bat >/dev/null 2>&1 || command -v batcat >/dev/null 2>&1; then
        echo "  ✓ Bat installed and available"
    else
        echo "  ❌ Bat was requested but not found in PATH"
        validation_failed=true
    fi
fi

if [ "${INSTALL_ZSH}" = "true" ]; then
    if command -v zsh >/dev/null 2>&1; then
        echo "  ✓ Zsh installed and available"
    else
        echo "  ❌ Zsh was requested but not found in PATH"
        validation_failed=true
    fi
fi

# Check shell configuration
if [ "${DEFAULT_SHELL}" = "zsh" ]; then
    if command -v zsh >/dev/null 2>&1; then
        echo "  ✓ Default shell (zsh) is available"
    else
        echo "  ⚠️  Default shell set to zsh but zsh is not installed"
        validation_failed=true
    fi
fi

if [ "$validation_failed" = "true" ]; then
    echo ""
    echo "⚠️  Some tools failed to install. This might be due to:"
    echo "    - Network connectivity issues"
    echo "    - Architecture not supported for some tools"
    echo "    - Repository access problems"
    echo "    The container should still be functional with the tools that did install."
    echo ""
fi

echo "✅ Common Utilities installation completed!"