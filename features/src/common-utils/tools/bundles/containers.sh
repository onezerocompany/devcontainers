#!/bin/bash
set -e

# ========================================
# CONTAINERS BUNDLE INSTALLATION
# ========================================

install_containers_bundle() {
    local install_kubernetes_tools="${1:-true}"
    local install_podman="${2:-true}"
    
    echo "🐳 Installing containers bundle..."

    # Install core container tools
    local container_packages="docker-compose containerd"
    
    # Add Podman tools if enabled
    if [ "$install_podman" = "true" ]; then
        echo "  Including Podman tools..."
        container_packages="$container_packages podman buildah skopeo"
    fi
    
    # Install container packages
    apt-get install -y $container_packages

    # Install container-related tools
    echo "📦 Installing container utilities..."

    # Install docker-compose-wait for development
    WAIT_URL="https://github.com/ufoscout/docker-compose-wait/releases/download/2.12.1/wait"
    echo "  Downloading docker-compose-wait from: $WAIT_URL"
    if curl -fsSL "$WAIT_URL" -o /usr/local/bin/docker-compose-wait; then
        chmod +x /usr/local/bin/docker-compose-wait
        echo "  ✓ docker-compose-wait installed successfully"
    else
        echo "  ⚠️  Failed to download docker-compose-wait, skipping"
        rm -f /usr/local/bin/docker-compose-wait
    fi

    # Install dive for Docker image analysis
    DIVE_VERSION="0.12.0"
    ARCH=$(dpkg --print-architecture)
    case $ARCH in
        amd64) DIVE_ARCH="amd64" ;;
        arm64) DIVE_ARCH="arm64" ;;
        *) echo "Unsupported architecture for dive: $ARCH"; echo "  ⚠️  Skipping dive installation"; return 0 ;;
    esac
    DIVE_URL="https://github.com/wagoodman/dive/releases/download/v${DIVE_VERSION}/dive_${DIVE_VERSION}_linux_${DIVE_ARCH}.deb"
    echo "  Downloading dive from: $DIVE_URL"
    if curl -fsSL "$DIVE_URL" -o /tmp/dive.deb; then
        if dpkg -i /tmp/dive.deb || apt-get install -f -y; then
            echo "  ✓ dive installed successfully"
        else
            echo "  ⚠️  Failed to install dive package"
        fi
        rm -f /tmp/dive.deb
    else
        echo "  ⚠️  Failed to download dive, skipping"
        rm -f /tmp/dive.deb
    fi

    # Install Kubernetes tools if enabled
    if [ "$install_kubernetes_tools" = "true" ]; then
        echo "  Installing Kubernetes tools..."
        
        # Install k9s (Kubernetes CLI)
        K9S_VERSION="0.32.4"
        case $ARCH in
            amd64) K9S_ARCH="amd64" ;;
            arm64) K9S_ARCH="arm64" ;;
            *) echo "Unsupported architecture for k9s: $ARCH"; echo "    ⚠️  Skipping k9s installation"; return 0 ;;
        esac
        K9S_URL="https://github.com/derailed/k9s/releases/download/v${K9S_VERSION}/k9s_Linux_${K9S_ARCH}.tar.gz"
        echo "    Downloading k9s from: $K9S_URL"
        if curl -fsSL "$K9S_URL" -o /tmp/k9s.tar.gz; then
            tar -xzf /tmp/k9s.tar.gz -C /tmp
            mv /tmp/k9s /usr/local/bin/
            chmod +x /usr/local/bin/k9s
            rm -f /tmp/k9s.tar.gz
            echo "    ✓ k9s installed successfully"
        else
            echo "    ⚠️  Failed to download k9s, skipping"
            rm -f /tmp/k9s.tar.gz
        fi

        # Install kubectl (Kubernetes client)
        echo "    Downloading kubectl stable version info..."
        if KUBECTL_VERSION=$(curl -fsSL "https://dl.k8s.io/release/stable.txt"); then
            KUBECTL_URL="https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl"
            echo "    Downloading kubectl ${KUBECTL_VERSION} from: $KUBECTL_URL"
            if curl -fsSL "$KUBECTL_URL" -o kubectl; then
                install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
                rm kubectl
                echo "    ✓ kubectl installed successfully"
            else
                echo "    ⚠️  Failed to download kubectl, skipping"
                rm -f kubectl
            fi
        else
            echo "    ⚠️  Failed to get kubectl version info, skipping"
        fi

        # Install helm (Kubernetes package manager)
        HELM_INSTALL_URL="https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3"
        echo "    Downloading helm installer from: $HELM_INSTALL_URL"
        if curl -fsSL "$HELM_INSTALL_URL" -o /tmp/helm-install.sh; then
            if [ -s /tmp/helm-install.sh ] && head -1 /tmp/helm-install.sh | grep -q '^#!/'; then
                chmod +x /tmp/helm-install.sh
                /tmp/helm-install.sh
                echo "    ✓ helm installed successfully"
            else
                echo "    ⚠️  Downloaded file is not a valid shell script, skipping helm installation"
            fi
            rm -f /tmp/helm-install.sh
        else
            echo "    ⚠️  Failed to download helm installer, skipping"
            rm -f /tmp/helm-install.sh
        fi
    fi

    echo "✓ Containers bundle installed"
}

# ========================================
# CONTAINERS BUNDLE CONFIGURATION
# ========================================

# Function to setup container tools for a user
setup_containers_for_user() {
    local user_home="$1"
    local username="$2"
    
    echo "  Setting up container tools for $username..."
    
    # Create directories
    mkdir -p "$user_home/.config"
    mkdir -p "$user_home/.kube"
    mkdir -p "$user_home/.local/share/bash-completion/completions"
    mkdir -p "$user_home/.local/share/zsh/site-functions"
    
    # Setup k9s config directory
    mkdir -p "$user_home/.config/k9s"
    
    # Create k9s config if it doesn't exist
    if [ ! -f "$user_home/.config/k9s/config.yaml" ]; then
        cat > "$user_home/.config/k9s/config.yaml" << 'EOF'
k9s:
  ui:
    enableMouse: true
    headless: false
    logoless: false
    crumbsless: false
    reactive: true
    noIcons: false
  skipLatestRevCheck: false
  disablePodCounting: false
  shellPod:
    image: busybox:1.35.0
    namespace: default
    limits:
      cpu: 100m
      memory: 100Mi
  logger:
    tail: 100
    buffer: 5000
    sinceSeconds: -1
    fullScreenLogs: false
    textWrap: false
    showTime: false
EOF
    fi
    
    # Setup completions for container tools
    if command -v kubectl >/dev/null 2>&1; then
        kubectl completion bash > "$user_home/.local/share/bash-completion/completions/kubectl" 2>/dev/null || true
        kubectl completion zsh > "$user_home/.local/share/zsh/site-functions/_kubectl" 2>/dev/null || true
    fi
    
    if command -v helm >/dev/null 2>&1; then
        helm completion bash > "$user_home/.local/share/bash-completion/completions/helm" 2>/dev/null || true
        helm completion zsh > "$user_home/.local/share/zsh/site-functions/_helm" 2>/dev/null || true
    fi
    
    # Set proper ownership
    if [ "$username" != "root" ]; then
        chown -R "$username:$username" "$user_home/.config" 2>/dev/null || true
        chown -R "$username:$username" "$user_home/.kube" 2>/dev/null || true
        chown -R "$username:$username" "$user_home/.local" 2>/dev/null || true
    fi
    
    echo "    ✓ Container tools configured for $username"
}

# Get container aliases for shell configuration
get_containers_aliases() {
    cat << 'EOF'
# Container aliases
alias d='docker'
alias dc='docker-compose'
alias dcu='docker-compose up'
alias dcd='docker-compose down'
alias dcl='docker-compose logs'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
alias drmf='docker rm -f'
alias drmi='docker rmi'
alias dprune='docker system prune -f'
alias dshell='docker run --rm -it'
alias k='kubectl'
alias kns='kubectl config set-context --current --namespace'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgd='kubectl get deployment'
alias kdesc='kubectl describe'
alias klogs='kubectl logs'
alias kexec='kubectl exec -it'
EOF
}