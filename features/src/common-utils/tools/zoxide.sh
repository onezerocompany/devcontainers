#!/bin/bash
set -e

# Source utils functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/utils.sh"

install_zoxide() {
    local INSTALL_ZOXIDE=${1:-true}
    local ZOXIDE_VERSION=${2:-"latest"}

    if [ "$INSTALL_ZOXIDE" != "true" ]; then
        echo "  ⚠️  zoxide installation skipped"
        return 0
    fi

    echo "📂 Installing zoxide (smart cd)..."

    # Get architecture
    local ARCH=$(uname -m)
    case $ARCH in
        x86_64) ZOXIDE_ARCH="x86_64" ;;
        aarch64|arm64) ZOXIDE_ARCH="aarch64" ;;
        *) echo "  ⚠️  Unsupported architecture: $ARCH"; return 1 ;;
    esac

    # Get latest version if not specified
    if [ "$ZOXIDE_VERSION" = "latest" ]; then
        echo "  🔍 Fetching latest zoxide version..."
        ZOXIDE_VERSION=$(get_latest_github_release "ajeetdsouza/zoxide")
        if [ -z "$ZOXIDE_VERSION" ]; then
            echo "  ⚠️  Failed to fetch latest version, using fallback"
            ZOXIDE_VERSION="0.9.6"
        else
            echo "  📋 Latest version: $ZOXIDE_VERSION"
        fi
    fi

    # Download and install zoxide
    local ZOXIDE_URL="https://github.com/ajeetdsouza/zoxide/releases/download/v${ZOXIDE_VERSION}/zoxide-${ZOXIDE_VERSION}-${ZOXIDE_ARCH}-unknown-linux-musl.tar.gz"
    
    echo "  📥 Downloading zoxide from: $ZOXIDE_URL"
    if curl -fsSL "$ZOXIDE_URL" -o /tmp/zoxide.tar.gz; then
        tar -xzf /tmp/zoxide.tar.gz -C /tmp
        mv /tmp/zoxide /usr/local/bin/zoxide
        chmod +x /usr/local/bin/zoxide
        rm -f /tmp/zoxide.tar.gz
        echo "  ✓ zoxide v${ZOXIDE_VERSION} installed successfully"
    else
        echo "  ⚠️  Failed to download zoxide"
        rm -f /tmp/zoxide.tar.gz
        return 1
    fi

    # Always setup initialization and aliases
    setup_zoxide_init
    setup_zoxide_aliases
}

setup_zoxide_init() {
    echo "  🔧 Setting up zoxide initialization..."
    
    # Add zoxide initialization for interactive shells only
    add_config "shared" "rc" "$(cat << 'EOF'
# Zoxide - Smarter cd command (interactive shells only)
if command -v zoxide >/dev/null 2>&1 && [[ $- == *i* ]]; then
    eval "$(zoxide init %SHELL%)"
fi
EOF
)"
    
    echo "  ✓ zoxide initialization configured"
}

setup_zoxide_aliases() {
    echo "  🔧 Setting up zoxide aliases..."
    
    # Add useful zoxide aliases (these work after zoxide init)
    add_alias "zoxide" "j" "z"  # Common shortcut for zoxide
    add_alias "zoxide" "ji" "zi"  # Interactive mode
    
    echo "  ✓ zoxide aliases configured"
}

# Check if zoxide should be installed (individual option or shell bundle)
if [ "${ZOXIDE:-true}" = "true" ]; then
    # Run installation
    ZOXIDE_VERSION=${ZOXIDE_VERSION:-"latest"}
    install_zoxide "true" "$ZOXIDE_VERSION"
else
    echo "  ⏭️  Skipping zoxide installation (disabled)"
fi