#!/bin/bash
set -e

# ========================================
# BAT INSTALLATION
# ========================================

echo "🦇 Installing bat (modern cat)..."
BAT_VERSION="0.24.0"
ARCH=$(get_architecture)
case $ARCH in
    amd64) BAT_ARCH="x86_64" ;;
    arm64) BAT_ARCH="aarch64" ;;
    *) echo "Unsupported architecture for bat: $ARCH"; echo "  ⚠️  Skipping bat installation"; exit 0 ;;
esac
BAT_URL="https://github.com/sharkdp/bat/releases/download/v${BAT_VERSION}/bat_${BAT_VERSION}_${ARCH}.deb"
echo "  Downloading bat from: $BAT_URL"
if curl -fsSL "$BAT_URL" -o /tmp/bat.deb; then
    if dpkg -i /tmp/bat.deb || apt-get install -f -y; then
        echo "  ✓ bat installed successfully"
    else
        echo "  ⚠️  Failed to install bat package"
    fi
    rm -f /tmp/bat.deb
else
    echo "  ⚠️  Failed to download bat, skipping"
    rm -f /tmp/bat.deb
fi

# ========================================
# BAT CONFIGURATION
# ========================================

# Function to add bat aliases to temporary config files
configure_bat_aliases() {
    # Define temporary file paths (consistent with utils.sh)
    local TMP_BASHRC="/tmp/tmp_bashrc"
    local TMP_ZSHRC="/tmp/tmp_zshrc"
    
    # Define bat alias content
    local bat_content=$(cat << 'EOF'
# Bat alias (modern cat)
alias cat='bat --paging=never'
EOF
)
    
    # Append to both bash and zsh tmp files
    echo "" >> "$TMP_BASHRC"
    echo "$bat_content" >> "$TMP_BASHRC"
    echo "" >> "$TMP_BASHRC"
    
    echo "" >> "$TMP_ZSHRC"
    echo "$bat_content" >> "$TMP_ZSHRC"
    echo "" >> "$TMP_ZSHRC"
}

# Get bat aliases content for template replacement
get_bat_aliases() {
    cat << 'EOF'
# Bat alias (modern cat)
alias cat='bat --paging=never'
EOF
}

# Configure bat aliases when script runs
if command -v bat >/dev/null 2>&1; then
    echo "  Writing bat aliases to temporary files..."
    configure_bat_aliases
fi