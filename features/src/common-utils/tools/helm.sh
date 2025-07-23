#!/bin/bash
set -e

# Source utils functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/utils.sh"

install_helm() {
    local INSTALL_HELM=${1:-true}
    local HELM_VERSION=${2:-"latest"}

    if [ "$INSTALL_HELM" != "true" ]; then
        echo "  ⚠️  Helm installation skipped"
        return 0
    fi

    echo "📦 Installing Helm..."

    # Get architecture
    local ARCH=$(uname -m)
    case $ARCH in
        x86_64) ARCH="amd64" ;;
        aarch64|arm64) ARCH="arm64" ;;
        *) echo "  ⚠️  Unsupported architecture: $ARCH"; return 1 ;;
    esac

    # Get latest version if not specified
    if [ "$HELM_VERSION" = "latest" ]; then
        echo "  🔍 Fetching latest Helm version..."
        HELM_VERSION=$(get_latest_github_release "helm/helm")
        if [ -z "$HELM_VERSION" ]; then
            echo "  ⚠️  Failed to fetch latest version, using fallback"
            HELM_VERSION="3.14.0"
        else
            echo "  📋 Latest version: $HELM_VERSION"
        fi
    fi

    # Download and install Helm
    local HELM_URL="https://get.helm.sh/helm-v${HELM_VERSION}-linux-${ARCH}.tar.gz"
    
    echo "  📥 Downloading Helm from: $HELM_URL"
    if curl -fsSL "$HELM_URL" -o /tmp/helm.tar.gz; then
        tar -xzf /tmp/helm.tar.gz -C /tmp
        mv "/tmp/linux-${ARCH}/helm" /usr/local/bin/
        chmod +x /usr/local/bin/helm
        rm -rf /tmp/helm.tar.gz "/tmp/linux-${ARCH}"
        echo "  ✓ Helm v${HELM_VERSION} installed successfully"
    else
        echo "  ⚠️  Failed to download Helm"
        rm -f /tmp/helm.tar.gz
        return 1
    fi

    # Always setup aliases and completion
    setup_helm_aliases
    setup_helm_completion
}

setup_helm_aliases() {
    echo "  🔧 Setting up Helm aliases..."
    
    # Common Helm aliases
    add_alias "helm" "h" "helm"
    add_alias "helm" "hls" "helm list"
    add_alias "helm" "hlsa" "helm list --all-namespaces"
    add_alias "helm" "hin" "helm install"
    add_alias "helm" "hup" "helm upgrade"
    add_alias "helm" "hun" "helm uninstall"
    add_alias "helm" "hst" "helm status"
    add_alias "helm" "hhi" "helm history"
    add_alias "helm" "hro" "helm rollback"
    add_alias "helm" "hse" "helm search"
    add_alias "helm" "hsh" "helm show"
    add_alias "helm" "hva" "helm show values"
    add_alias "helm" "hre" "helm repo"
    add_alias "helm" "hrea" "helm repo add"
    add_alias "helm" "hreu" "helm repo update"
    add_alias "helm" "hrel" "helm repo list"
    add_alias "helm" "hget" "helm get"
    add_alias "helm" "hgv" "helm get values"
    add_alias "helm" "hgm" "helm get manifest"
    
    echo "  ✓ Helm aliases configured"
}

setup_helm_completion() {
    echo "  🔧 Setting up Helm completion..."
    
    # Add Helm completion for both shells with alias support
    add_completion "helm" "shared" "h"
    
    echo "  ✓ Helm completion configured"
}

# Run installation with environment variables
INSTALL_HELM=${HELM:-true}
HELM_VERSION=${HELM_VERSION:-"latest"}

install_helm "$INSTALL_HELM" "$HELM_VERSION"