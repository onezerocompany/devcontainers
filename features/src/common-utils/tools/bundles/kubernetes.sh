#!/bin/bash
set -e

# Ensure non-interactive mode for apt
export DEBIAN_FRONTEND=noninteractive

# ========================================
# KUBERNETES BUNDLE INSTALLATION
# ========================================

install_kubernetes_bundle() {
    echo "☸️  Installing Kubernetes bundle..."

    # Get system architecture
    ARCH=$(dpkg --print-architecture)
    case $ARCH in
        amd64) K8S_ARCH="amd64" ;;
        arm64) K8S_ARCH="arm64" ;;
        *) echo "Unsupported architecture for Kubernetes tools: $ARCH"; echo "  ⚠️  Skipping Kubernetes installation"; return 0 ;;
    esac

    # Install kubectl (Kubernetes client)
    echo "📦 Installing kubectl..."
    if KUBECTL_VERSION_RAW=$(curl -fsSL "https://dl.k8s.io/release/stable.txt"); then
        # Validate version format (should be v1.xx.xx)
        if [[ "$KUBECTL_VERSION_RAW" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            KUBECTL_VERSION="$KUBECTL_VERSION_RAW"
            KUBECTL_URL="https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${K8S_ARCH}/kubectl"
            echo "  Downloading kubectl ${KUBECTL_VERSION} from: $KUBECTL_URL"
            if curl -fsSL "$KUBECTL_URL" -o kubectl; then
                install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
                rm kubectl
                echo "  ✓ kubectl installed successfully"
            else
                echo "  ⚠️  Failed to download kubectl, skipping"
                rm -f kubectl
            fi
        else
            echo "  ⚠️  Invalid kubectl version format received: $KUBECTL_VERSION_RAW, skipping"
        fi
    else
        echo "  ⚠️  Failed to get kubectl version info, skipping"
    fi

    # Install k9s (Kubernetes CLI UI)
    echo "📦 Installing k9s..."
    K9S_VERSION="0.32.4"
    K9S_URL="https://github.com/derailed/k9s/releases/download/v${K9S_VERSION}/k9s_Linux_${K8S_ARCH}.tar.gz"
    echo "  Downloading k9s from: $K9S_URL"
    if curl -fsSL "$K9S_URL" -o /tmp/k9s.tar.gz; then
        tar -xzf /tmp/k9s.tar.gz -C /tmp
        mv /tmp/k9s /usr/local/bin/
        chmod +x /usr/local/bin/k9s
        rm -f /tmp/k9s.tar.gz
        echo "  ✓ k9s installed successfully"
    else
        echo "  ⚠️  Failed to download k9s, skipping"
        rm -f /tmp/k9s.tar.gz
    fi

    # Install helm (Kubernetes package manager)
    echo "📦 Installing helm..."
    HELM_INSTALL_URL="https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3"
    echo "  Downloading helm installer from: $HELM_INSTALL_URL"
    if curl -fsSL "$HELM_INSTALL_URL" -o /tmp/helm-install.sh; then
        if [ -s /tmp/helm-install.sh ] && head -1 /tmp/helm-install.sh | grep -q '^#!/'; then
            chmod +x /tmp/helm-install.sh
            /tmp/helm-install.sh
            echo "  ✓ helm installed successfully"
        else
            echo "  ⚠️  Downloaded file is not a valid shell script, skipping helm installation"
        fi
        rm -f /tmp/helm-install.sh
    else
        echo "  ⚠️  Failed to download helm installer, skipping"
        rm -f /tmp/helm-install.sh
    fi

    # Install kustomize (Kubernetes configuration management)
    echo "📦 Installing kustomize..."
    KUSTOMIZE_URL="https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"
    echo "  Downloading kustomize installer from: $KUSTOMIZE_URL"
    if curl -fsSL "$KUSTOMIZE_URL" -o /tmp/kustomize-install.sh; then
        if [ -s /tmp/kustomize-install.sh ] && head -1 /tmp/kustomize-install.sh | grep -q '^#!/'; then
            chmod +x /tmp/kustomize-install.sh
            cd /tmp && ./kustomize-install.sh
            mv /tmp/kustomize /usr/local/bin/
            chmod +x /usr/local/bin/kustomize
            echo "  ✓ kustomize installed successfully"
        else
            echo "  ⚠️  Downloaded file is not a valid shell script, skipping kustomize installation"
        fi
        rm -f /tmp/kustomize-install.sh /tmp/kustomize
    else
        echo "  ⚠️  Failed to download kustomize installer, skipping"
        rm -f /tmp/kustomize-install.sh
    fi

    # Install Flux CD (GitOps toolkit)
    echo "📦 Installing Flux CD..."
    FLUX_VERSION="2.2.3"
    FLUX_URL="https://github.com/fluxcd/flux2/releases/download/v${FLUX_VERSION}/flux_${FLUX_VERSION}_linux_${K8S_ARCH}.tar.gz"
    echo "  Downloading Flux CD from: $FLUX_URL"
    if curl -fsSL "$FLUX_URL" -o /tmp/flux.tar.gz; then
        tar -xzf /tmp/flux.tar.gz -C /tmp
        mv /tmp/flux /usr/local/bin/
        chmod +x /usr/local/bin/flux
        rm -f /tmp/flux.tar.gz
        echo "  ✓ Flux CD installed successfully"
    else
        echo "  ⚠️  Failed to download Flux CD, skipping"
        rm -f /tmp/flux.tar.gz
    fi

    # Install kind (Kubernetes in Docker)
    echo "📦 Installing kind..."
    KIND_VERSION="0.20.0"
    KIND_URL="https://kind.sigs.k8s.io/dl/v${KIND_VERSION}/kind-linux-${K8S_ARCH}"
    echo "  Downloading kind from: $KIND_URL"
    if curl -fsSL "$KIND_URL" -o /usr/local/bin/kind; then
        chmod +x /usr/local/bin/kind
        echo "  ✓ kind installed successfully"
    else
        echo "  ⚠️  Failed to download kind, skipping"
        rm -f /usr/local/bin/kind
    fi

    echo "✅ Kubernetes bundle installed"
}

# ========================================
# KUBERNETES BUNDLE CONFIGURATION
# ========================================

# Function to setup Kubernetes tools for a user
setup_kubernetes_for_user() {
    local user_home="$1"
    local username="$2"
    
    echo "  Setting up Kubernetes tools for $username..."
    
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
    
    # Setup completions for Kubernetes tools
    if command -v kubectl >/dev/null 2>&1; then
        kubectl completion bash > "$user_home/.local/share/bash-completion/completions/kubectl" 2>/dev/null || true
        kubectl completion zsh > "$user_home/.local/share/zsh/site-functions/_kubectl" 2>/dev/null || true
    fi
    
    if command -v helm >/dev/null 2>&1; then
        helm completion bash > "$user_home/.local/share/bash-completion/completions/helm" 2>/dev/null || true
        helm completion zsh > "$user_home/.local/share/zsh/site-functions/_helm" 2>/dev/null || true
    fi

    if command -v flux >/dev/null 2>&1; then
        flux completion bash > "$user_home/.local/share/bash-completion/completions/flux" 2>/dev/null || true
        flux completion zsh > "$user_home/.local/share/zsh/site-functions/_flux" 2>/dev/null || true
    fi

    if command -v kind >/dev/null 2>&1; then
        kind completion bash > "$user_home/.local/share/bash-completion/completions/kind" 2>/dev/null || true
        kind completion zsh > "$user_home/.local/share/zsh/site-functions/_kind" 2>/dev/null || true
    fi
    
    # Set proper ownership
    if [ "$username" != "root" ]; then
        chown -R "$username:$username" "$user_home/.config" 2>/dev/null || true
        chown -R "$username:$username" "$user_home/.kube" 2>/dev/null || true
        chown -R "$username:$username" "$user_home/.local" 2>/dev/null || true
    fi
    
    echo "    ✓ Kubernetes tools configured for $username"
}

# Get Kubernetes aliases for shell configuration
get_kubernetes_aliases() {
    cat << 'EOF'
# Kubernetes aliases
alias k='kubectl'
alias kns='kubectl config set-context --current --namespace'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgd='kubectl get deployment'
alias kgi='kubectl get ingress'
alias kgn='kubectl get nodes'
alias kdesc='kubectl describe'
alias klogs='kubectl logs'
alias kexec='kubectl exec -it'
alias kctx='kubectl config current-context'
alias kswitch='kubectl config use-context'
alias kports='kubectl get svc --all-namespaces -o wide'
alias kwhoami='kubectl auth whoami'

# Helm aliases
alias h='helm'
alias hls='helm list'
alias hla='helm list --all-namespaces'
alias hup='helm upgrade'
alias hin='helm install'
alias hun='helm uninstall'

# Flux aliases
alias f='flux'
alias fget='flux get all'
alias fsync='flux reconcile source git'
alias fhr='flux reconcile helmrelease'
alias fks='flux reconcile kustomization'

# Kind aliases
alias kcreate='kind create cluster'
alias kdelete='kind delete cluster'
alias klist='kind get clusters'
EOF
}