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

# Function to add zoxide initialization to shell config files
configure_zoxide_init() {
    local config_file="$1"
    local shell_name="$2"
    local marker_start="# >>> Zoxide init - START >>>"
    local marker_end="# <<< Zoxide init - END <<<"
    
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
    
    # Append zoxide initialization
    cat >> "$config_file" << EOF

$marker_start
# Zoxide - Smarter cd command (interactive shells only)
if command -v zoxide >/dev/null 2>&1 && [[ \$- == *i* ]]; then
    eval "\$(zoxide init $shell_name)"
fi
$marker_end
EOF
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