#!/bin/bash
set -e

# Source utils functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/utils.sh"

install_k9s() {
    local INSTALL_K9S=${1:-true}
    local K9S_VERSION=${2:-"latest"}

    if [ "$INSTALL_K9S" != "true" ]; then
        echo "  ⚠️  K9s installation skipped"
        return 0
    fi

    echo "📦 Installing K9s..."

    # Get architecture
    local ARCH=$(uname -m)
    case $ARCH in
        x86_64) ARCH="amd64" ;;
        aarch64|arm64) ARCH="arm64" ;;
        *) echo "  ⚠️  Unsupported architecture: $ARCH"; return 1 ;;
    esac

    # Get latest version if not specified
    if [ "$K9S_VERSION" = "latest" ]; then
        echo "  🔍 Fetching latest K9s version..."
        K9S_VERSION=$(get_latest_github_release "derailed/k9s")
        if [ -z "$K9S_VERSION" ]; then
            echo "  ⚠️  Failed to fetch latest version, using fallback"
            K9S_VERSION="0.31.7"
        else
            echo "  📋 Latest version: $K9S_VERSION"
        fi
    fi

    # Download and install K9s
    local K9S_URL="https://github.com/derailed/k9s/releases/download/v${K9S_VERSION}/k9s_Linux_${ARCH}.tar.gz"
    
    echo "  📥 Downloading K9s from: $K9S_URL"
    if curl -fsSL "$K9S_URL" -o /tmp/k9s.tar.gz; then
        tar -xzf /tmp/k9s.tar.gz -C /tmp
        mv /tmp/k9s /usr/local/bin/
        chmod +x /usr/local/bin/k9s
        rm -f /tmp/k9s.tar.gz /tmp/LICENSE /tmp/README.md
        echo "  ✓ K9s v${K9S_VERSION} installed successfully"
    else
        echo "  ⚠️  Failed to download K9s"
        rm -f /tmp/k9s.tar.gz
        return 1
    fi

    # Always setup aliases and config
    setup_k9s_aliases
    setup_k9s_config
}

setup_k9s_aliases() {
    echo "  🔧 Setting up K9s aliases..."
    
    # K9s aliases for different contexts/namespaces
    add_alias "k9s" "k9" "k9s"
    add_alias "k9s" "k9s-info" "k9s info"
    add_alias "k9s" "k9s-version" "k9s version"
    
    echo "  ✓ K9s aliases configured"
}

setup_k9s_config() {
    echo "  🔧 Setting up K9s configuration..."
    
    local USER_NAME=$(username)
    local USER_HOME=$(user_home)
    
    # Create K9s config directory
    local K9S_CONFIG_DIR="${USER_HOME}/.config/k9s"
    mkdir -p "$K9S_CONFIG_DIR"
    
    # Create basic K9s configuration
    cat > "${K9S_CONFIG_DIR}/config.yaml" << 'EOF'
# K9s configuration
k9s:
  # Refresh rate in seconds
  refreshRate: 2
  # Max number of logs lines
  maxConnRetry: 5
  # Enable mouse support
  enableMouse: false
  # Headless mode
  headless: false
  # Logo less
  logoless: false
  # Crumb less
  crumbsless: false
  # Read only mode
  readOnly: false
  # No icons mode
  noIcons: false
  # Logger configuration
  logger:
    tail: 100
    buffer: 5000
    sinceSeconds: -1
    textWrap: false
    showTime: false
  # Current cluster/context
  currentContext: ""
  # Current namespace
  currentCluster: ""
  # Clusters configuration
  clusters: {}
EOF

    # Set ownership if not root
    if [ "$USER_NAME" != "root" ]; then
        chown -R "$USER_NAME:$USER_NAME" "$K9S_CONFIG_DIR"
    fi
    
    echo "  ✓ K9s configuration created at ${K9S_CONFIG_DIR}/config.yaml"
}

# Run installation with environment variables
INSTALL_K9S=${K9S:-true}
K9S_VERSION=${K9S_VERSION:-"latest"}

install_k9s "$INSTALL_K9S" "$K9S_VERSION"