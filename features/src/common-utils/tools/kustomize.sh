#!/bin/bash
set -e

# Source utils functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/utils.sh"

install_kustomize() {
    local INSTALL_KUSTOMIZE=${1:-true}
    local KUSTOMIZE_VERSION=${2:-"latest"}

    if [ "$INSTALL_KUSTOMIZE" != "true" ]; then
        echo "  ⚠️  Kustomize installation skipped"
        return 0
    fi

    echo "📦 Installing Kustomize..."

    # Get architecture
    local ARCH=$(uname -m)
    case $ARCH in
        x86_64) ARCH="amd64" ;;
        aarch64|arm64) ARCH="arm64" ;;
        *) echo "  ⚠️  Unsupported architecture: $ARCH"; return 1 ;;
    esac

    # Get latest version if not specified
    if [ "$KUSTOMIZE_VERSION" = "latest" ]; then
        echo "  🔍 Fetching latest Kustomize version..."
        # Note: kustomize releases have a specific format with kustomize/ prefix
        local FULL_VERSION=$(curl -s "https://api.github.com/repos/kubernetes-sigs/kustomize/releases" \
            | grep '"tag_name":' \
            | grep "kustomize/" \
            | head -n1 \
            | sed -E 's/.*"kustomize\/v([^"]+)".*/\1/')
        
        if [ -z "$FULL_VERSION" ]; then
            echo "  ⚠️  Failed to fetch latest version, using fallback"
            KUSTOMIZE_VERSION="5.3.0"
        else
            KUSTOMIZE_VERSION="$FULL_VERSION"
            echo "  📋 Latest version: $KUSTOMIZE_VERSION"
        fi
    fi

    # Download and install Kustomize
    local KUSTOMIZE_URL="https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${KUSTOMIZE_VERSION}/kustomize_v${KUSTOMIZE_VERSION}_linux_${ARCH}.tar.gz"
    
    echo "  📥 Downloading Kustomize from: $KUSTOMIZE_URL"
    if curl -fsSL "$KUSTOMIZE_URL" -o /tmp/kustomize.tar.gz; then
        tar -xzf /tmp/kustomize.tar.gz -C /tmp
        mv /tmp/kustomize /usr/local/bin/
        chmod +x /usr/local/bin/kustomize
        rm -f /tmp/kustomize.tar.gz
        echo "  ✓ Kustomize v${KUSTOMIZE_VERSION} installed successfully"
    else
        echo "  ⚠️  Failed to download Kustomize"
        rm -f /tmp/kustomize.tar.gz
        return 1
    fi

    # Always setup aliases and completion
    setup_kustomize_aliases
    setup_kustomize_completion
}

setup_kustomize_aliases() {
    echo "  🔧 Setting up Kustomize aliases..."
    
    # Common Kustomize aliases
    add_alias "kustomize" "kz" "kustomize"
    add_alias "kustomize" "kzb" "kustomize build"
    add_alias "kustomize" "kzc" "kustomize create"
    add_alias "kustomize" "kze" "kustomize edit"
    add_alias "kustomize" "kzv" "kustomize version"
    add_alias "kustomize" "kzcfg" "kustomize cfg"
    add_alias "kustomize" "kzfn" "kustomize fn"
    
    # Common build patterns
    add_alias "kustomize" "kzba" "kustomize build --enable-alpha-plugins"
    add_alias "kustomize" "kzbh" "kustomize build --enable-helm"
    
    echo "  ✓ Kustomize aliases configured"
}

setup_kustomize_completion() {
    echo "  🔧 Setting up Kustomize completion..."
    
    # Add Kustomize completion for both shells with alias support
    add_completion "kustomize" "shared" "kz"
    
    echo "  ✓ Kustomize completion configured"
}

# Run installation with environment variables
INSTALL_KUSTOMIZE=${KUSTOMIZE:-true}
KUSTOMIZE_VERSION=${KUSTOMIZE_VERSION:-"latest"}

install_kustomize "$INSTALL_KUSTOMIZE" "$KUSTOMIZE_VERSION"