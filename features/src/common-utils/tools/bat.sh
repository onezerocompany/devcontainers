#!/bin/bash
set -e

# Source utils functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/utils.sh"

install_bat() {
    local INSTALL_BAT=${1:-true}
    local BAT_VERSION=${2:-"latest"}

    if [ "$INSTALL_BAT" != "true" ]; then
        echo "  ⚠️  bat installation skipped"
        return 0
    fi

    echo "🦇 Installing bat (modern cat)..."

    # Get architecture
    local ARCH=$(uname -m)
    case $ARCH in
        x86_64) ARCH="amd64" ;;
        aarch64|arm64) ARCH="arm64" ;;
        *) echo "  ⚠️  Unsupported architecture: $ARCH"; return 1 ;;
    esac

    # Get latest version if not specified
    if [ "$BAT_VERSION" = "latest" ]; then
        echo "  🔍 Fetching latest bat version..."
        BAT_VERSION=$(get_latest_github_release "sharkdp/bat")
        if [ -z "$BAT_VERSION" ]; then
            echo "  ⚠️  Failed to fetch latest version, using fallback"
            BAT_VERSION="0.24.0"
        else
            echo "  📋 Latest version: $BAT_VERSION"
        fi
    fi

    # Download and install bat
    local BAT_URL="https://github.com/sharkdp/bat/releases/download/v${BAT_VERSION}/bat_${BAT_VERSION}_${ARCH}.deb"
    
    echo "  📥 Downloading bat from: $BAT_URL"
    if curl -fsSL "$BAT_URL" -o /tmp/bat.deb; then
        if dpkg -i /tmp/bat.deb || apt-get install -f -y; then
            echo "  ✓ bat v${BAT_VERSION} installed successfully"
        else
            echo "  ⚠️  Failed to install bat package"
            rm -f /tmp/bat.deb
            return 1
        fi
        rm -f /tmp/bat.deb
    else
        echo "  ⚠️  Failed to download bat"
        rm -f /tmp/bat.deb
        return 1
    fi

    # Always setup aliases and config
    setup_bat_aliases
    setup_bat_config
}

setup_bat_aliases() {
    echo "  🔧 Setting up bat aliases..."
    
    # Replace cat with bat for better syntax highlighting
    add_alias "bat" "cat" "bat --paging=never"
    add_alias "bat" "ccat" "bat --paging=never --color=always"
    add_alias "bat" "less" "bat --paging=always"
    
    echo "  ✓ bat aliases configured"
}

setup_bat_config() {
    echo "  🔧 Setting up bat configuration..."
    
    local USER_NAME=$(username)
    local USER_HOME=$(user_home)
    
    # Create bat config directory
    local BAT_CONFIG_DIR="${USER_HOME}/.config/bat"
    mkdir -p "$BAT_CONFIG_DIR"
    
    # Create bat configuration
    cat > "${BAT_CONFIG_DIR}/config" << 'EOF'
# bat configuration
--theme="OneHalfDark"
--style="numbers,changes,header"
--wrap="auto"
--pager="less -FR"
EOF

    # Set ownership if not root
    if [ "$USER_NAME" != "root" ]; then
        chown -R "$USER_NAME:$USER_NAME" "$BAT_CONFIG_DIR"
    fi
    
    echo "  ✓ bat configuration created at ${BAT_CONFIG_DIR}/config"
}

# Check if bat should be installed
if [ "${BAT:-true}" = "true" ]; then
    # Run installation
    BAT_VERSION=${BAT_VERSION:-"latest"}
    install_bat "true" "$BAT_VERSION"
else
    echo "  ⏭️  Skipping bat installation (disabled)"
fi