#!/bin/bash
set -e

# Source utils functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/utils.sh"

install_kind() {
    local INSTALL_KIND=${1:-true}
    local KIND_VERSION=${2:-"latest"}

    if [ "$INSTALL_KIND" != "true" ]; then
        echo "  ⚠️  Kind installation skipped"
        return 0
    fi

    echo "📦 Installing Kind..."

    # Check for Docker dependency
    if ! command -v docker >/dev/null 2>&1; then
        echo "  ⚠️  Docker is required for Kind but not found"
        echo "  💡 Install Docker first or use the docker-in-docker feature"
        return 1
    fi

    # Get architecture
    local ARCH=$(uname -m)
    case $ARCH in
        x86_64) ARCH="amd64" ;;
        aarch64|arm64) ARCH="arm64" ;;
        *) echo "  ⚠️  Unsupported architecture: $ARCH"; return 1 ;;
    esac

    # Get latest version if not specified
    if [ "$KIND_VERSION" = "latest" ]; then
        echo "  🔍 Fetching latest Kind version..."
        KIND_VERSION=$(get_latest_github_release "kubernetes-sigs/kind")
        if [ -z "$KIND_VERSION" ]; then
            echo "  ⚠️  Failed to fetch latest version, using fallback"
            KIND_VERSION="0.20.0"
        else
            echo "  📋 Latest version: $KIND_VERSION"
        fi
    fi

    # Download and install Kind
    local KIND_URL="https://kind.sigs.k8s.io/dl/v${KIND_VERSION}/kind-linux-${ARCH}"
    
    echo "  📥 Downloading Kind from: $KIND_URL"
    if curl -fsSL "$KIND_URL" -o /tmp/kind; then
        install -m 755 /tmp/kind /usr/local/bin/kind
        rm -f /tmp/kind
        echo "  ✓ Kind v${KIND_VERSION} installed successfully"
    else
        echo "  ⚠️  Failed to download Kind"
        rm -f /tmp/kind
        return 1
    fi

    # Always setup aliases, completion, and config
    setup_kind_aliases
    setup_kind_completion  
    setup_kind_config
}

setup_kind_aliases() {
    echo "  🔧 Setting up Kind aliases..."
    
    # Common Kind aliases
    add_alias "kind" "kic" "kind create cluster"
    add_alias "kind" "kid" "kind delete cluster"
    add_alias "kind" "kig" "kind get clusters"
    add_alias "kind" "kikc" "kind get kubeconfig"
    add_alias "kind" "kiln" "kind load docker-image"
    add_alias "kind" "kile" "kind export kubeconfig"
    
    echo "  ✓ Kind aliases configured"
}

setup_kind_completion() {
    echo "  🔧 Setting up Kind completion..."
    
    # Add Kind completion for both shells (no alias needed)
    add_completion "kind" "shared"
    
    echo "  ✓ Kind completion configured"
}

setup_kind_config() {
    echo "  🔧 Setting up Kind configuration..."
    
    local USER_NAME=$(username)
    local USER_HOME=$(user_home)
    
    # Create Kind config directory
    local KIND_CONFIG_DIR="${USER_HOME}/.kind"
    mkdir -p "$KIND_CONFIG_DIR"
    
    # Create a sample Kind cluster configuration
    cat > "${KIND_CONFIG_DIR}/sample-config.yaml" << 'EOF'
# Sample Kind cluster configuration
# Usage: kind create cluster --config ~/.kind/sample-config.yaml --name my-cluster
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: kind-cluster
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
- role: worker
- role: worker
EOF

    # Create a simple single-node configuration
    cat > "${KIND_CONFIG_DIR}/single-node.yaml" << 'EOF'
# Single node Kind cluster configuration
# Usage: kind create cluster --config ~/.kind/single-node.yaml --name single
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: single-node
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 80
    hostPort: 8080
    protocol: TCP
  - containerPort: 443
    hostPort: 8443
    protocol: TCP
EOF

    # Set ownership if not root
    if [ "$USER_NAME" != "root" ]; then
        chown -R "$USER_NAME:$USER_NAME" "$KIND_CONFIG_DIR"
    fi
    
    echo "  ✓ Kind configuration created at ${KIND_CONFIG_DIR}/"
    echo "    - sample-config.yaml: Multi-node cluster with ingress"
    echo "    - single-node.yaml: Single node cluster"
}

# Run installation with environment variables
INSTALL_KIND=${KIND:-true}
KIND_VERSION=${KIND_VERSION:-"latest"}

install_kind "$INSTALL_KIND" "$KIND_VERSION"