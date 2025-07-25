#!/usr/bin/env bash
set -e

VERSION="${VERSION:-"latest"}"
CONFIGURE_CACHE="${CONFIGURECACHE:-"true"}"
AUTO_TRUST="${AUTOTRUST:-"true"}"
USE_BUN_FOR_NPM="${USEBUNFORNPM:-"false"}"

USERNAME="${USERNAME:-"${_REMOTE_USER:-"automatic"}"}"

# Ensure we have curl
if ! command -v curl &> /dev/null; then
    apt-get update -y
    apt-get install -y curl ca-certificates
fi

# Determine the user
if [ "${USERNAME}" = "auto" ] || [ "${USERNAME}" = "automatic" ]; then
    USERNAME=""
    POSSIBLE_USERS=("vscode" "node" "codespace" "zero" "$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd)")
    for CURRENT_USER in "${POSSIBLE_USERS[@]}"; do
        if id -u "${CURRENT_USER}" > /dev/null 2>&1; then
            USERNAME="${CURRENT_USER}"
            break
        fi
    done
    if [ "${USERNAME}" = "" ]; then
        USERNAME=root
    fi
elif [ "${USERNAME}" = "none" ] || ! id -u ${USERNAME} > /dev/null 2>&1; then
    USERNAME=root
fi

# Get user home directory
if [ "${USERNAME}" = "root" ]; then
    USER_HOME="/root"
else
    USER_HOME="/home/${USERNAME}"
fi

# Install mise
echo "Installing mise version: ${VERSION}..."
if [ "${VERSION}" = "latest" ]; then
    curl -fsSL https://mise.run | sh
else
    curl -fsSL https://mise.run | MISE_VERSION="${VERSION}" sh
fi

# Move mise to system location
mv "${USER_HOME}/.local/bin/mise" /usr/local/bin/mise
chmod +x /usr/local/bin/mise

# Copy initialization script
cp "$(dirname "$0")/mise-init.sh" /usr/local/bin/mise-init
chmod +x /usr/local/bin/mise-init

# Configure mise directories for volume mounting
if [ "${CONFIGURE_CACHE}" = "true" ]; then
    # Create all mise directories that will be volume mounted
    MISE_CACHE_DIR="${USER_HOME}/.cache/mise"
    MISE_INSTALLS_DIR="${USER_HOME}/.local/share/mise"
    MISE_CONFIG_DIR="${USER_HOME}/.config/mise"
    
    mkdir -p "${MISE_CACHE_DIR}"
    mkdir -p "${MISE_INSTALLS_DIR}"
    mkdir -p "${MISE_CONFIG_DIR}"
    
    if [ "${USERNAME}" != "root" ]; then
        chown -R "${USERNAME}:${USERNAME}" "${MISE_CACHE_DIR}"
        chown -R "${USERNAME}:${USERNAME}" "${MISE_INSTALLS_DIR}"
        chown -R "${USERNAME}:${USERNAME}" "${MISE_CONFIG_DIR}"
    fi
fi

# Set up shell integration for both user and root
setup_shell_integration() {
    local target_user="$1"
    local target_home="$2"
    
    # Ensure .local/bin exists
    mkdir -p "${target_home}/.local/bin"
    
    # Configure for bash
    if [ -f "${target_home}/.bashrc" ]; then
        echo '' >> "${target_home}/.bashrc"
        echo '# mise-en-place' >> "${target_home}/.bashrc"
        echo 'export PATH="${HOME}/.local/bin:${PATH}"' >> "${target_home}/.bashrc"
        echo "export MISE_AUTO_TRUST=\"${AUTO_TRUST}\"" >> "${target_home}/.bashrc"
        echo '# Auto-initialize mise on first use' >> "${target_home}/.bashrc"
        echo 'if [ ! -f "${HOME}/.local/share/mise/.initialized" ] && [ -x /usr/local/bin/mise-init ]; then' >> "${target_home}/.bashrc"
        echo '    /usr/local/bin/mise-init' >> "${target_home}/.bashrc"
        echo 'fi' >> "${target_home}/.bashrc"
        echo 'eval "$(mise activate bash)"' >> "${target_home}/.bashrc"
    fi
    
    # Configure for zsh
    if [ -f "${target_home}/.zshrc" ]; then
        echo '' >> "${target_home}/.zshrc"
        echo '# mise-en-place' >> "${target_home}/.zshrc"
        echo 'export PATH="${HOME}/.local/bin:${PATH}"' >> "${target_home}/.zshrc"
        echo "export MISE_AUTO_TRUST=\"${AUTO_TRUST}\"" >> "${target_home}/.zshrc"
        echo '# Auto-initialize mise on first use' >> "${target_home}/.zshrc"
        echo 'if [ ! -f "${HOME}/.local/share/mise/.initialized" ] && [ -x /usr/local/bin/mise-init ]; then' >> "${target_home}/.zshrc"
        echo '    /usr/local/bin/mise-init' >> "${target_home}/.zshrc"
        echo 'fi' >> "${target_home}/.zshrc"
        echo 'eval "$(mise activate zsh)"' >> "${target_home}/.zshrc"
    fi
    
    # Create mise directories
    mkdir -p "${target_home}/.config/mise"
    mkdir -p "${target_home}/.local/share/mise"
    
    # Set ownership if not root
    if [ "${target_user}" != "root" ]; then
        chown -R "${target_user}:${target_user}" "${target_home}/.local"
        chown -R "${target_user}:${target_user}" "${target_home}/.config/mise"
        if [ "${CONFIGURE_CACHE}" = "true" ]; then
            chown -R "${target_user}:${target_user}" "${target_home}/.cache/mise" 2>/dev/null || true
            chown -R "${target_user}:${target_user}" "${target_home}/.local/share/mise" 2>/dev/null || true
        fi
    fi
}

# Setup for the main user
setup_shell_integration "${USERNAME}" "${USER_HOME}"

# Also setup for root if we're not already root
if [ "${USERNAME}" != "root" ]; then
    setup_shell_integration "root" "/root"
fi

# Configure mise settings if bun backend is requested
if [ "${USE_BUN_FOR_NPM}" = "true" ]; then
    echo "Configuring mise to use bun as npm backend..."
    
    # Create mise settings file with bun backend configuration
    mkdir -p /etc/mise
    cat > /etc/mise/config.toml << 'EOF'
[settings]
node_compile = false
not_found_auto_install = true
experimental = true
bun_backend = true
EOF
    
    # Also create default user config with bun backend
    cat > "${USER_HOME}/.config/mise/config.toml" << 'EOF'
[settings]
node_compile = false
not_found_auto_install = true
experimental = true
bun_backend = true
EOF
    
    if [ "${USERNAME}" != "root" ]; then
        chown "${USERNAME}:${USERNAME}" "${USER_HOME}/.config/mise/config.toml"
    fi
fi

# Note: mise directories will be initialized on first container start via mise-init
# This ensures proper setup after volumes are mounted

echo "mise-en-place installation complete!"