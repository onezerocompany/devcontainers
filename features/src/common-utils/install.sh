#!/bin/bash
# Common Utilities Feature Installation Script

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load error handling framework
source "${SCRIPT_DIR}/lib/error_handling.sh"

# Initialize error handling
setup_error_handling

# Ensure non-interactive mode for apt
export DEBIAN_FRONTEND=noninteractive

# Feature options
DEFAULT_SHELL="${DEFAULTSHELL:-zsh}"
INSTALL_STARSHIP="${STARSHIP:-true}"
INSTALL_ZOXIDE="${ZOXIDE:-true}"
INSTALL_EZA="${EZA:-true}"
INSTALL_BAT="${BAT:-true}"
INSTALL_ZSH="${ZSH:-true}"
INSTALL_WEBDEV_BUNDLE="${WEBDEV:-false}"
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
INSTALL_DATABASE_CLIENTS="${DATABASECLIENTS:-false}"
INSTALL_GITHUB_CLI="${GITHUBCLI:-false}"

# Get the non-root user
USERNAME="${_REMOTE_USER:-"automatic"}"
if [ "${USERNAME}" = "auto" ] || [ "${USERNAME}" = "automatic" ]; then
    USERNAME=""
    # Safely get user with UID 1000, validate it's alphanumeric
    UID_1000_USER=$(awk -v val=1000 -F ":" '$3==val{print $1; exit}' /etc/passwd | head -n1)
    if [ -n "$UID_1000_USER" ] && [[ "$UID_1000_USER" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        POSSIBLE_USERS=("zero" "vscode" "node" "codespace" "$UID_1000_USER")
    else
        POSSIBLE_USERS=("zero" "vscode" "node" "codespace")
    fi
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

log_info "Installing Common Utilities for user: ${USERNAME}"

# ========================================
# ========================================
# APT PACKAGES
# ========================================

# Create temporary policy-rc.d to prevent service restarts during package installation
# This prevents "policy-rc.d denied execution" and dbus/systemd related errors
echo '#!/bin/sh
exit 101' > /usr/sbin/policy-rc.d
chmod +x /usr/sbin/policy-rc.d

installation_step "apt_update" "Updating package repositories" \
    network_operation "apt_update" apt-get update

# Base packages (always install)
BASE_PACKAGES="curl wget git bash ca-certificates gnupg"

# Add zsh to packages if enabled
if [ "${INSTALL_ZSH}" = "true" ]; then
    BASE_PACKAGES="$BASE_PACKAGES zsh"
    log_info "Added zsh to package list"
fi

installation_step "base_packages" "Installing base packages: $BASE_PACKAGES" \
    apt-get install -y $BASE_PACKAGES

# ========================================
# DEPENDENCY AND SYSTEM CHECKS
# ========================================

installation_step "system_checks" "Performing system compatibility checks" \
    check_dependencies "curl" "wget" "apt-get"

installation_step "disk_space_check" "Checking available disk space" \
    check_disk_space 512  # Require 512MB free space

installation_step "permission_check" "Checking system permissions" \
    check_permissions "/usr/local/bin" "w"

# ========================================
# MODERN CLI TOOLS INSTALLATION
# ========================================

# Make tool scripts executable
find "${SCRIPT_DIR}/tools" -name "*.sh" -type f -exec chmod +x {} \;

# Source function files that contain installation functions
[ -f "${SCRIPT_DIR}/tools/shell/motd.sh" ] && source "${SCRIPT_DIR}/tools/shell/motd.sh"
[ -f "${SCRIPT_DIR}/tools/utils.sh" ] && source "${SCRIPT_DIR}/tools/utils.sh"
[ -f "${SCRIPT_DIR}/tools/mise.sh" ] && source "${SCRIPT_DIR}/tools/mise.sh"

# Initialize temporary configuration files that tools will write to
init_tmp_config_files

# Source bundle functions
for bundle_script in "${SCRIPT_DIR}"/tools/bundles/*.sh; do
    if [ -f "$bundle_script" ]; then
        source "$bundle_script"
    fi
done

# Install tools based on options
if [ "${INSTALL_STARSHIP}" = "true" ]; then
    installation_step "starship_install" "Installing Starship prompt" \
        "${SCRIPT_DIR}/tools/shell/starship/starship.sh" || log_warn "Starship installation failed, continuing..."
fi

if [ "${INSTALL_ZOXIDE}" = "true" ]; then
    installation_step "zoxide_install" "Installing Zoxide smart cd" \
        "${SCRIPT_DIR}/tools/shell/zoxide.sh" || log_warn "Zoxide installation failed, continuing..."
fi

if [ "${INSTALL_EZA}" = "true" ]; then
    installation_step "eza_install" "Installing Eza modern ls" \
        "${SCRIPT_DIR}/tools/shell/eza.sh" || log_warn "Eza installation failed, continuing..."
fi

if [ "${INSTALL_BAT}" = "true" ]; then
    installation_step "bat_install" "Installing Bat syntax highlighter" \
        "${SCRIPT_DIR}/tools/shell/bat.sh" || log_warn "Bat installation failed, continuing..."
fi

# Install tool bundles based on options
if [ "${INSTALL_WEBDEV_BUNDLE}" = "true" ]; then
    installation_step "webdev_bundle" "Installing web development bundle" \
        install_webdev_bundle "$INSTALL_DATABASE_CLIENTS" || log_warn "Web development bundle had errors"
fi

if [ "${INSTALL_NETWORKING_BUNDLE}" = "true" ]; then
    installation_step "networking_bundle" "Installing networking bundle" \
        install_networking_bundle || log_warn "Networking bundle had errors"
fi

if [ "${INSTALL_KUBERNETES_BUNDLE}" = "true" ]; then
    installation_step "kubernetes_bundle" "Installing Kubernetes bundle" \
        install_kubernetes_bundle || log_warn "Kubernetes bundle had errors"
fi

if [ "${INSTALL_UTILITIES_BUNDLE}" = "true" ]; then
    installation_step "utilities_bundle" "Installing utilities bundle" \
        install_utilities_bundle "$INSTALL_BUILD_TOOLS" "$INSTALL_GITHUB_CLI" || log_warn "Utilities bundle had errors"
fi

# Remove the temporary policy-rc.d after all package installations are complete
rm -f /usr/sbin/policy-rc.d

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
    # Validate username contains only safe characters and construct path safely
    if [[ "$USERNAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        USER_HOME="/home/$USERNAME"
    else
        echo "Error: Invalid username '$USERNAME' contains unsafe characters"
        exit 1
    fi
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

# Determine shell path dynamically
if [ "${DEFAULT_SHELL}" = "zsh" ] && [ "${INSTALL_ZSH}" = "true" ]; then
    SHELL_PATH=$(command -v zsh)
    if [ -z "$SHELL_PATH" ]; then
        echo "Warning: zsh installation requested but zsh not found in PATH, falling back to bash"
        SHELL_PATH=$(command -v bash || echo "/bin/bash")
    fi
elif [ "${DEFAULT_SHELL}" = "zsh" ] && [ "${INSTALL_ZSH}" = "false" ]; then
    echo "Warning: defaultShell is set to 'zsh' but zsh installation is disabled, falling back to bash"
    SHELL_PATH=$(command -v bash || echo "/bin/bash")
elif [ "${DEFAULT_SHELL}" = "bash" ]; then
    SHELL_PATH=$(command -v bash || echo "/bin/bash")
else
    echo "Warning: Unknown shell '${DEFAULT_SHELL}', defaulting to bash"
    SHELL_PATH=$(command -v bash || echo "/bin/bash")
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

installation_step "installation_validation" "Validating installation completeness" \
    validate_installation_completeness

installation_step "health_check" "Performing installation health check" \
    validate_installation_health || log_warn "Health check found issues but installation can continue"

# Attempt partial recovery if there were any errors during installation
if [ "$ERROR_COUNT" -gt 0 ]; then
    log_warn "Installation completed with errors, attempting partial recovery"
    recover_partial_installation
fi

echo "✅ Common Utilities installation completed!"