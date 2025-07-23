#!/bin/bash
set -e

# Source utils functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/utils.sh"

install_kubectl() {
    local INSTALL_KUBECTL=${1:-true}
    local KUBECTL_VERSION=${2:-"latest"}

    if [ "$INSTALL_KUBECTL" != "true" ]; then
        echo "  ⚠️  kubectl installation skipped"
        return 0
    fi

    echo "📦 Installing kubectl..."

    # Get architecture using utility function
    local ARCH=$(get_architecture)

    # Get latest stable version if not specified
    if [ "$KUBECTL_VERSION" = "latest" ]; then
        echo "  🔍 Fetching latest kubectl version..."
        KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt | sed 's/^v//')
        if [ -z "$KUBECTL_VERSION" ]; then
            echo "  ⚠️  Failed to fetch latest version, using fallback"
            KUBECTL_VERSION="1.29.0"
        else
            echo "  📋 Latest version: $KUBECTL_VERSION"
        fi
    fi

    # Download and install kubectl
    local KUBECTL_URL="https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl"
    
    echo "  📥 Downloading kubectl from: $KUBECTL_URL"
    local kubectl_log="/tmp/kubectl-install.log"
    
    if curl -fsSL "$KUBECTL_URL" -o /tmp/kubectl 2>"$kubectl_log"; then
        if install -m 755 /tmp/kubectl /usr/local/bin/kubectl 2>>"$kubectl_log"; then
            rm -f /tmp/kubectl "$kubectl_log"
            echo "  ✓ kubectl v${KUBECTL_VERSION} installed successfully"
        else
            echo "  ❌ Failed to install kubectl binary" >&2
            echo "  📄 Error details:" >&2
            sed 's/^/    /' "$kubectl_log" >&2
            rm -f /tmp/kubectl "$kubectl_log"
            return 1
        fi
    else
        echo "  ❌ Failed to download kubectl" >&2
        echo "  🌐 URL: $KUBECTL_URL" >&2
        echo "  📄 Error details:" >&2
        sed 's/^/    /' "$kubectl_log" >&2
        rm -f /tmp/kubectl "$kubectl_log"
        return 1
    fi

    # Always setup aliases and completion
    setup_kubectl_aliases
    setup_kubectl_completion
}

setup_kubectl_aliases() {
    echo "  🔧 Setting up kubectl aliases..."
    
    # Common kubectl aliases
    add_alias "kubectl" "k" "kubectl"
    add_alias "kubectl" "kgp" "kubectl get pods"
    add_alias "kubectl" "kgs" "kubectl get services"
    add_alias "kubectl" "kgd" "kubectl get deployments"
    add_alias "kubectl" "kgn" "kubectl get namespaces"
    add_alias "kubectl" "kdp" "kubectl describe pod"
    add_alias "kubectl" "kds" "kubectl describe service"
    add_alias "kubectl" "kdd" "kubectl describe deployment"
    add_alias "kubectl" "kl" "kubectl logs"
    add_alias "kubectl" "klf" "kubectl logs -f"
    add_alias "kubectl" "kex" "kubectl exec -it"
    add_alias "kubectl" "kpf" "kubectl port-forward"
    add_alias "kubectl" "kdel" "kubectl delete"
    add_alias "kubectl" "kap" "kubectl apply"
    add_alias "kubectl" "kctx" "kubectl config current-context"
    add_alias "kubectl" "kns" "kubectl config set-context --current --namespace"
    
    echo "  ✓ kubectl aliases configured"
}

setup_kubectl_completion() {
    echo "  🔧 Setting up kubectl completion..."
    
    # Add kubectl completion for both shells with alias support
    add_completion "kubectl" "shared" "k"
    
    echo "  ✓ kubectl completion configured"
}

# Check if kubectl should be installed
if [ "${KUBECTL:-true}" = "true" ]; then
    # Run installation
    KUBECTL_VERSION=${KUBECTL_VERSION:-"latest"}
    install_kubectl "true" "$KUBECTL_VERSION"
else
    echo "  ⏭️  Skipping kubectl installation (disabled)"
fi