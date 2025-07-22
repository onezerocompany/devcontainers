#!/bin/bash
set -e

# ========================================
# STARSHIP INSTALLATION
# ========================================

echo "⭐ Installing Starship prompt..."
STARSHIP_INSTALL_URL="https://starship.rs/install.sh"
echo "  Downloading starship installer from: $STARSHIP_INSTALL_URL"
if curl -fsSL "$STARSHIP_INSTALL_URL" -o /tmp/starship-install.sh; then
    if [ -s /tmp/starship-install.sh ] && head -1 /tmp/starship-install.sh | grep -q '^#!/'; then
        chmod +x /tmp/starship-install.sh
        /tmp/starship-install.sh -y
        echo "  ✓ starship installed successfully"
    else
        echo "  ⚠️  Downloaded file is not a valid shell script, skipping starship installation"
    fi
    rm -f /tmp/starship-install.sh
else
    echo "  ⚠️  Failed to download starship installer, skipping"
    rm -f /tmp/starship-install.sh
fi

# ========================================
# STARSHIP CONFIGURATION
# ========================================

# Function to add starship initialization to temporary config files
configure_starship_init() {
    local shell_name="$1"
    
    # Define temporary file paths (consistent with utils.sh)
    local TMP_BASHRC="/tmp/tmp_bashrc"
    local TMP_ZSHRC="/tmp/tmp_zshrc"
    
    # Define starship init content
    local starship_content=$(cat << 'EOF'
# Starship - Cross-shell prompt (interactive shells only)
if command -v starship >/dev/null 2>&1 && [[ $- == *i* ]]; then
    eval "$(starship init SHELL_PLACEHOLDER)"
fi
EOF
)
    
    # Replace shell placeholder
    starship_content=$(echo "$starship_content" | sed "s/SHELL_PLACEHOLDER/$shell_name/g")
    
    # Append to appropriate tmp files
    if [ "$shell_name" = "bash" ]; then
        echo "" >> "$TMP_BASHRC"
        echo "$starship_content" >> "$TMP_BASHRC"
        echo "" >> "$TMP_BASHRC"
    elif [ "$shell_name" = "zsh" ]; then
        echo "" >> "$TMP_ZSHRC"
        echo "$starship_content" >> "$TMP_ZSHRC"
        echo "" >> "$TMP_ZSHRC"
    fi
}

# Function to install starship configuration
install_starship_config() {
    local user_home="$1"
    local configs_dir="$2"
    
    mkdir -p "$user_home/.config"
    
    # Check for existing starship config
    if [ -f "$user_home/.config/starship.toml" ]; then
        echo "  Found existing starship.toml, will be replaced"
    fi
    
    # Get the script directory to find starship config
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local starship_config="$script_dir/starship/starship.toml"
    
    if [ -f "$starship_config" ]; then
        cp "$starship_config" "$user_home/.config/starship.toml"
        echo "  Installed starship configuration"
    fi
}

# Get starship init content for template replacement
get_starship_init() {
    local shell_name="$1"
    cat << EOF
# Starship - Cross-shell prompt (interactive shells only)
if command -v starship >/dev/null 2>&1 && [[ \$- == *i* ]]; then
    eval "\$(starship init $shell_name)"
fi
EOF
}

# Configure starship for both bash and zsh when script runs
if command -v starship >/dev/null 2>&1; then
    echo "  Writing starship configuration to temporary files..."
    configure_starship_init "bash"
    configure_starship_init "zsh"
fi