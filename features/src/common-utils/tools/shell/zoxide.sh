#!/bin/bash
set -e

# ========================================
# ZOXIDE INSTALLATION
# ========================================

echo "📂 Installing zoxide (smart cd)..."
ZOXIDE_VERSION="0.9.6"
ARCH=$(dpkg --print-architecture)
case $ARCH in
    amd64) ZOXIDE_ARCH="x86_64" ;;
    arm64) ZOXIDE_ARCH="aarch64" ;;
    *) echo "Unsupported architecture for zoxide: $ARCH"; echo "  ⚠️  Skipping zoxide installation"; return 0 ;;
esac
ZOXIDE_URL="https://github.com/ajeetdsouza/zoxide/releases/download/v${ZOXIDE_VERSION}/zoxide-${ZOXIDE_VERSION}-${ZOXIDE_ARCH}-unknown-linux-musl.tar.gz"
echo "  Downloading zoxide from: $ZOXIDE_URL"
if curl -fsSL "$ZOXIDE_URL" -o /tmp/zoxide.tar.gz; then
    tar -xzf /tmp/zoxide.tar.gz -C /tmp
    mv /tmp/zoxide /usr/local/bin/zoxide
    chmod +x /usr/local/bin/zoxide
    rm -f /tmp/zoxide.tar.gz
    echo "  ✓ zoxide installed successfully"
else
    echo "  ⚠️  Failed to download zoxide, skipping"
    rm -f /tmp/zoxide.tar.gz
fi

# ========================================
# ZOXIDE CONFIGURATION
# ========================================

# Function to add zoxide initialization to temporary config files
configure_zoxide_init() {
    local shell_name="$1"
    
    # Define zoxide init content
    local zoxide_content=$(cat << 'EOF'
# Zoxide - Smarter cd command (interactive shells only)
if command -v zoxide >/dev/null 2>&1 && [[ $- == *i* ]]; then
    eval "$(zoxide init SHELL_PLACEHOLDER)"
fi
EOF
)
    
    # Replace shell placeholder
    zoxide_content=$(echo "$zoxide_content" | sed "s/SHELL_PLACEHOLDER/$shell_name/g")
    
    # Append to appropriate tmp files
    if [ "$shell_name" = "bash" ]; then
        echo "" >> /tmp/tmp_bashrc
        echo "$zoxide_content" >> /tmp/tmp_bashrc
        echo "" >> /tmp/tmp_bashrc
    elif [ "$shell_name" = "zsh" ]; then
        echo "" >> /tmp/tmp_zshrc
        echo "$zoxide_content" >> /tmp/tmp_zshrc
        echo "" >> /tmp/tmp_zshrc
    fi
}

# Get zoxide init content for template replacement
get_zoxide_init() {
    local shell_name="$1"
    cat << EOF
# Zoxide - Smarter cd command (interactive shells only)
if command -v zoxide >/dev/null 2>&1 && [[ \$- == *i* ]]; then
    eval "\$(zoxide init $shell_name)"
fi
EOF
}

# Configure zoxide for both bash and zsh when script runs
if command -v zoxide >/dev/null 2>&1; then
    echo "  Writing zoxide configuration to temporary files..."
    configure_zoxide_init "bash"
    configure_zoxide_init "zsh"
fi