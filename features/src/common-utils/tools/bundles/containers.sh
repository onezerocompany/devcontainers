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
    curl -L https://github.com/ufoscout/docker-compose-wait/releases/download/2.12.1/wait -o /usr/local/bin/docker-compose-wait
    chmod +x /usr/local/bin/docker-compose-wait

    # Install dive for Docker image analysis
    DIVE_VERSION="0.12.0"
    ARCH=$(dpkg --print-architecture)
    case $ARCH in
        amd64) DIVE_ARCH="amd64" ;;
        arm64) DIVE_ARCH="arm64" ;;
        *) echo "Unsupported architecture for dive: $ARCH"; return 0 ;;
    esac
    curl -L "https://github.com/wagoodman/dive/releases/download/v${DIVE_VERSION}/dive_${DIVE_VERSION}_linux_${DIVE_ARCH}.deb" -o /tmp/dive.deb
    dpkg -i /tmp/dive.deb || apt-get install -f -y
    rm -f /tmp/dive.deb

    # Install Kubernetes tools if enabled
    if [ "$install_kubernetes_tools" = "true" ]; then
        echo "  Installing Kubernetes tools..."
        
        # Install k9s (Kubernetes CLI)
        K9S_VERSION="0.32.4"
        case $ARCH in
            amd64) K9S_ARCH="amd64" ;;
            arm64) K9S_ARCH="arm64" ;;
            *) echo "Unsupported architecture for k9s: $ARCH"; return 0 ;;
        esac
        curl -L "https://github.com/derailed/k9s/releases/download/v${K9S_VERSION}/k9s_Linux_${K9S_ARCH}.tar.gz" -o /tmp/k9s.tar.gz
        tar -xzf /tmp/k9s.tar.gz -C /tmp
        mv /tmp/k9s /usr/local/bin/
        chmod +x /usr/local/bin/k9s
        rm -f /tmp/k9s.tar.gz

        # Install kubectl (Kubernetes client)
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH}/kubectl"
        install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
        rm kubectl

        # Install helm (Kubernetes package manager)
        curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
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