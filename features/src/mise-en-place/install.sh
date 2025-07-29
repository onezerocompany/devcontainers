#!/usr/bin/env bash
set -e

VERSION="${VERSION:-"latest"}"
AUTO_TRUST="${AUTOTRUST:-"true"}"
INSTALL_NODE_LTS="${INSTALLNODELTS:-"true"}"

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

# Install mise with retry logic
echo "Installing mise version: ${VERSION}..."
MAX_RETRIES=5
RETRY_DELAY=5

# Function to download mise with retries
download_mise() {
    local attempt=1
    while [ $attempt -le $MAX_RETRIES ]; do
        echo "Attempting to download mise (attempt $attempt/$MAX_RETRIES)..."
        
        # Try to download mise
        if [ "${VERSION}" = "latest" ]; then
            if curl -fsSL https://mise.run | sh; then
                echo "Successfully downloaded and installed mise"
                return 0
            fi
        else
            if curl -fsSL https://mise.run | MISE_VERSION="${VERSION}" sh; then
                echo "Successfully downloaded and installed mise version ${VERSION}"
                return 0
            fi
        fi
        
        # If we get here, the download failed
        if [ $attempt -lt $MAX_RETRIES ]; then
            echo "Download failed, retrying in ${RETRY_DELAY} seconds..."
            sleep $RETRY_DELAY
        fi
        
        attempt=$((attempt + 1))
    done
    
    echo "ERROR: Failed to download mise after $MAX_RETRIES attempts"
    return 1
}

# Download mise with retry logic
if ! download_mise; then
    echo "Failed to install mise"
    exit 1
fi

# Move mise to system location
# Find where mise was actually installed (could be in root's home during container build)
echo "Looking for mise binary..."
echo "USER_HOME: ${USER_HOME}"
echo "Current user: $(whoami)"

# Check all possible locations
if [ -f "${USER_HOME}/.local/bin/mise" ]; then
    echo "Found mise at ${USER_HOME}/.local/bin/mise"
    mv "${USER_HOME}/.local/bin/mise" /usr/local/bin/mise
elif [ -f "/root/.local/bin/mise" ]; then
    echo "Found mise at /root/.local/bin/mise"
    mv "/root/.local/bin/mise" /usr/local/bin/mise
else
    echo "ERROR: Could not find mise binary in expected locations:"
    echo "  - ${USER_HOME}/.local/bin/mise"
    echo "  - /root/.local/bin/mise"
    echo "Contents of ${USER_HOME}/.local/bin/:"
    ls -la "${USER_HOME}/.local/bin/" 2>/dev/null || echo "Directory does not exist"
    echo "Contents of /root/.local/bin/:"
    ls -la "/root/.local/bin/" 2>/dev/null || echo "Directory does not exist"
    exit 1
fi
chmod +x /usr/local/bin/mise

# Copy initialization script
cp "$(dirname "$0")/mise-init.sh" /usr/local/bin/mise-init
chmod +x /usr/local/bin/mise-init


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
        echo 'export BUN_INSTALL="${HOME}/.bun"' >> "${target_home}/.bashrc"
        echo 'export PATH="${HOME}/.local/bin:${HOME}/.bun/bin:${PATH}"' >> "${target_home}/.bashrc"
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
        echo 'export BUN_INSTALL="${HOME}/.bun"' >> "${target_home}/.zshrc"
        echo 'export PATH="${HOME}/.local/bin:${HOME}/.bun/bin:${PATH}"' >> "${target_home}/.zshrc"
        echo "export MISE_AUTO_TRUST=\"${AUTO_TRUST}\"" >> "${target_home}/.zshrc"
        echo '# Auto-initialize mise on first use' >> "${target_home}/.zshrc"
        echo 'if [ ! -f "${HOME}/.local/share/mise/.initialized" ] && [ -x /usr/local/bin/mise-init ]; then' >> "${target_home}/.zshrc"
        echo '    /usr/local/bin/mise-init' >> "${target_home}/.zshrc"
        echo 'fi' >> "${target_home}/.zshrc"
        echo 'eval "$(mise activate zsh)"' >> "${target_home}/.zshrc"
    fi
    
    # Create mise directories with proper structure
    mkdir -p "${target_home}/.config/mise"
    mkdir -p "${target_home}/.local/share/mise"
    mkdir -p "${target_home}/.local/share/mise/installs"
    mkdir -p "${target_home}/.local/share/mise/cache"
    mkdir -p "${target_home}/.local/share/mise/downloads"
    mkdir -p "${target_home}/.cache/mise"
    mkdir -p "${target_home}/.cache/mise/lockfiles"
    mkdir -p "${target_home}/.bun/bin"
    mkdir -p "${target_home}/.cache/mise/node"
    mkdir -p "${target_home}/.local/state/mise"
    
    # Set proper permissions for bun directories
    chmod 755 "${target_home}/.bun"
    chmod 755 "${target_home}/.bun/bin"
    
    # Set ownership if not root
    if [ "${target_user}" != "root" ]; then
        chown -R "${target_user}:${target_user}" "${target_home}/.local"
        chown -R "${target_user}:${target_user}" "${target_home}/.config/mise"
        chown -R "${target_user}:${target_user}" "${target_home}/.local/share/mise"
        chown -R "${target_user}:${target_user}" "${target_home}/.cache/mise"
        chown -R "${target_user}:${target_user}" "${target_home}/.local/state/mise"
        chown -R "${target_user}:${target_user}" "${target_home}/.bun"
    fi
}

# Setup for the main user
setup_shell_integration "${USERNAME}" "${USER_HOME}"

# Also setup for root if we're not already root
if [ "${USERNAME}" != "root" ]; then
    setup_shell_integration "root" "/root"
fi

# Configure mise settings for both user and root
echo "Configuring mise settings..."

# Remove any existing problematic system config to avoid conflicts
# We'll only use user-level config to avoid permission issues
rm -f /etc/mise/config.toml

# Function to create mise config for a user
create_mise_config() {
    local target_user="$1"
    local target_home="$2"
    
    # Ensure config directory exists
    mkdir -p "${target_home}/.config/mise"
    
    # Check mise version to determine which settings to use
    MISE_VERSION_OUTPUT=$(mise --version 2>/dev/null || echo "")
    if echo "${MISE_VERSION_OUTPUT}" | grep -q "2024\.1\." || echo "${MISE_VERSION_OUTPUT}" | grep -q "2023\."; then
        # Older mise version - use minimal config
        cat > "${target_home}/.config/mise/config.toml" << 'EOF'
[settings]
experimental = true

[env]
BUN_INSTALL = "~/.bun"
EOF
    else
        # Newer mise version - use full config
        cat > "${target_home}/.config/mise/config.toml" << 'EOF'
[settings]
not_found_auto_install = true
experimental = true

[env]
BUN_INSTALL = "~/.bun"
EOF
    fi
    
    # Set ownership if not root
    if [ "${target_user}" != "root" ]; then
        chown "${target_user}:${target_user}" "${target_home}/.config/mise/config.toml"
    fi
}

# Create config for main user
create_mise_config "${USERNAME}" "${USER_HOME}"

# Also create config for root if we're not already root
if [ "${USERNAME}" != "root" ]; then
    create_mise_config "root" "/root"
fi

# Install Node.js LTS globally if requested
if [ "${INSTALL_NODE_LTS}" = "true" ]; then
    echo "Installing Node.js LTS globally..."
    
    # Trust the config files first if auto-trust is enabled
    if [ "${AUTO_TRUST}" = "true" ]; then
        echo "Auto-trusting mise config files..."
        # Trust the main user's config
        if [ "${USERNAME}" != "root" ]; then
            su - "${USERNAME}" -c "mise trust ${USER_HOME}/.config/mise/config.toml" 2>/dev/null || true
        else
            cd "${USER_HOME}" && mise trust "${USER_HOME}/.config/mise/config.toml" 2>/dev/null || true
        fi
        
        # Trust root's config if we're not already root
        if [ "${USERNAME}" != "root" ]; then
            cd "/root" && mise trust "/root/.config/mise/config.toml" 2>/dev/null || true
        fi
    fi
    
    # Install as the main user
    if [ "${USERNAME}" != "root" ]; then
        su - "${USERNAME}" -c "mise use -g node@lts"
    else
        cd "${USER_HOME}" && mise use -g node@lts
    fi
    
    # Also install for root if we're not already root
    if [ "${USERNAME}" != "root" ]; then
        cd "/root" && mise use -g node@lts
    fi
    
    echo "Node.js LTS installed globally via mise"
fi

# Note: mise directories will be initialized on first container start via mise-init
# This ensures proper setup after volumes are mounted

echo "mise-en-place installation complete!"