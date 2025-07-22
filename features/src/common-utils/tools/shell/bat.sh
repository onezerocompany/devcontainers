#!/bin/bash
set -e

# ========================================
# BAT INSTALLATION
# ========================================

echo "🦇 Installing bat (modern cat)..."
BAT_VERSION="0.24.0"
ARCH=$(dpkg --print-architecture)
case $ARCH in
    amd64) BAT_ARCH="x86_64" ;;
    arm64) BAT_ARCH="aarch64" ;;
    *) echo "Unsupported architecture for bat: $ARCH"; echo "  ⚠️  Skipping bat installation"; return 0 ;;
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

# Function to add bat aliases to shell config files
configure_bat_aliases() {
    local config_file="$1"
    local marker_start="# >>> Bat aliases - START >>>"
    local marker_end="# <<< Bat aliases - END <<<"
    
    # Check if already configured
    if [ -f "$config_file" ] && grep -q "$marker_start" "$config_file"; then
        return 0
    fi
    
    # Create file if it doesn't exist
    if [ ! -f "$config_file" ]; then
        touch "$config_file"
    fi
    
    # Add newline if file doesn't end with one
    if [ -s "$config_file" ] && [ "$(tail -c 1 "$config_file")" != "" ]; then
        echo "" >> "$config_file"
    fi
    
    # Append bat alias
    cat >> "$config_file" << EOF

$marker_start
# Bat alias (modern cat)
alias cat='bat --paging=never'
$marker_end
EOF
}

# Get bat aliases content for template replacement
get_bat_aliases() {
    cat << 'EOF'
# Bat alias (modern cat)
alias cat='bat --paging=never'
EOF
}