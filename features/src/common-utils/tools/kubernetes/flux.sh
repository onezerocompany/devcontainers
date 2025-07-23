#!/bin/bash
set -e

# Source utils functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/utils.sh"

install_flux() {
    local INSTALL_FLUX=${1:-true}
    local FLUX_VERSION=${2:-"latest"}

    if [ "$INSTALL_FLUX" != "true" ]; then
        echo "  ⚠️  Flux CD installation skipped"
        return 0
    fi

    echo "📦 Installing Flux CD..."

    # Get architecture
    local ARCH=$(uname -m)
    case $ARCH in
        x86_64) ARCH="amd64" ;;
        aarch64|arm64) ARCH="arm64" ;;
        *) echo "  ⚠️  Unsupported architecture: $ARCH"; return 1 ;;
    esac

    # Get latest version if not specified
    if [ "$FLUX_VERSION" = "latest" ]; then
        echo "  🔍 Fetching latest Flux CD version..."
        FLUX_VERSION=$(get_latest_github_release "fluxcd/flux2")
        if [ -z "$FLUX_VERSION" ]; then
            echo "  ⚠️  Failed to fetch latest version, using fallback"
            FLUX_VERSION="2.2.3"
        else
            echo "  📋 Latest version: $FLUX_VERSION"
        fi
    fi

    local FLUX_URL="https://github.com/fluxcd/flux2/releases/download/v${FLUX_VERSION}/flux_${FLUX_VERSION}_linux_${ARCH}.tar.gz"
    
    echo "  📥 Downloading Flux CD from: $FLUX_URL"
    if curl -fsSL "$FLUX_URL" -o /tmp/flux.tar.gz; then
        tar -xzf /tmp/flux.tar.gz -C /tmp
        mv /tmp/flux /usr/local/bin/
        chmod +x /usr/local/bin/flux
        rm -f /tmp/flux.tar.gz
        echo "  ✓ Flux CD v${FLUX_VERSION} installed successfully"
    else
        echo "  ⚠️  Failed to download Flux CD, skipping"
        rm -f /tmp/flux.tar.gz
        return 1
    fi

    # Always setup aliases and completion
    setup_flux_aliases
    setup_flux_completion
}

setup_flux_aliases() {
    echo "  🔧 Setting up Flux CD aliases..."
    
    # Common Flux CD aliases
    add_alias "flux" "fluxget" "flux get all"
    add_alias "flux" "fluxlogs" "flux logs --follow"
    add_alias "flux" "fluxreconcile" "flux reconcile source git"
    add_alias "flux" "fluxsuspend" "flux suspend"
    add_alias "flux" "fluxresume" "flux resume"
    add_alias "flux" "fluxcheck" "flux check"
    add_alias "flux" "fluxbootstrap" "flux bootstrap"
    add_alias "flux" "fluxuninstall" "flux uninstall"
    add_alias "flux" "fluxexport" "flux export"
    add_alias "flux" "fluxstats" "flux stats"
    
    echo "  ✓ Flux CD aliases configured"
}

setup_flux_completion() {
    echo "  🔧 Setting up Flux CD completion..."
    
    # Add Flux completion for both shells (no alias needed)
    add_completion "flux" "shared"
    
    echo "  ✓ Flux CD completion configured"
}

# Run installation with environment variables
INSTALL_FLUX=${FLUX:-true}
FLUX_VERSION=${FLUX_VERSION:-"latest"}

install_flux "$INSTALL_FLUX" "$FLUX_VERSION"