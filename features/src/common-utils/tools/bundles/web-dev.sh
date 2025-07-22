#!/bin/bash
set -e

# ========================================
# WEB DEVELOPMENT BUNDLE INSTALLATION
# ========================================

install_webdev_bundle() {
    local install_database_clients="${1:-true}"

    echo "🌐 Installing web development bundle..."

    # Install core web development tools
    apt-get install -y \
        httpie \
        jq \
        xmlstarlet \
        nginx \
        apache2-utils

    # Install database clients if enabled
    if [ "$install_database_clients" = "true" ]; then
        echo "  Installing database clients..."
        apt-get install -y \
            postgresql-client \
            sqlite3 \
            redis-tools
    fi

    # Install yq binary (not available as package)
    echo "📦 Installing yq..."
    YQ_VERSION="4.43.1"
    ARCH=$(dpkg --print-architecture)
    case $ARCH in
        amd64) YQ_ARCH="amd64" ;;
        arm64) YQ_ARCH="arm64" ;;
        *) echo "Unsupported architecture for yq: $ARCH"; YQ_ARCH="amd64" ;;
    esac
    curl -L "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_${YQ_ARCH}" -o /usr/local/bin/yq
    chmod +x /usr/local/bin/yq

    # Install modern config tools
    echo "📦 Installing config processing tools..."

    # Install dasel (universal config query tool)
    DASEL_VERSION="2.8.1"
    ARCH=$(dpkg --print-architecture)
    case $ARCH in
        amd64) DASEL_ARCH="amd64" ;;
        arm64) DASEL_ARCH="arm64" ;;
        *) echo "Unsupported architecture for dasel: $ARCH"; return 0 ;;
    esac
    curl -L "https://github.com/TomWright/dasel/releases/download/v${DASEL_VERSION}/dasel_linux_${DASEL_ARCH}" -o /usr/local/bin/dasel
    chmod +x /usr/local/bin/dasel

    # Install yj (YAML/TOML/JSON/HCL converter)
    YJ_VERSION="5.1.0"
    case $ARCH in
        amd64) YJ_ARCH="amd64" ;;
        arm64) YJ_ARCH="arm64" ;;
        *) echo "Unsupported architecture for yj: $ARCH"; return 0 ;;
    esac
    curl -L "https://github.com/sclevine/yj/releases/download/v${YJ_VERSION}/yj-linux-${YJ_ARCH}" -o /usr/local/bin/yj
    chmod +x /usr/local/bin/yj

    # Install miller (data processing tool)
    MILLER_VERSION="6.12.0"
    case $ARCH in
        amd64) MILLER_ARCH="amd64" ;;
        arm64) MILLER_ARCH="arm64" ;;
        *) echo "Unsupported architecture for miller: $ARCH"; return 0 ;;
    esac
    MILLER_URL="https://github.com/johnkerl/miller/releases/download/v${MILLER_VERSION}/miller-${MILLER_VERSION}-linux-${MILLER_ARCH}.tar.gz"
    echo "  Downloading miller from: $MILLER_URL"
    if curl -fsSL "$MILLER_URL" -o /tmp/miller.tar.gz; then
        tar -xzf /tmp/miller.tar.gz -C /tmp
        mv "/tmp/miller-${MILLER_VERSION}-linux-${MILLER_ARCH}/mlr" /usr/local/bin/
        chmod +x /usr/local/bin/mlr
        rm -rf /tmp/miller*
        echo "  ✓ miller installed successfully"
    else
        echo "  ⚠️  Failed to download miller, skipping"
        rm -rf /tmp/miller*
    fi

    # Install httpstat (HTTP request statistics)
    HTTPSTAT_URL="https://raw.githubusercontent.com/reorx/httpstat/master/httpstat.py"
    echo "  Downloading httpstat from: $HTTPSTAT_URL"
    if curl -fsSL "$HTTPSTAT_URL" -o /usr/local/bin/httpstat; then
        chmod +x /usr/local/bin/httpstat
        echo "  ✓ httpstat installed successfully"
    else
        echo "  ⚠️  Failed to download httpstat, skipping"
        rm -f /usr/local/bin/httpstat
    fi

    echo "✅ Web development bundle installed"
}

# ========================================
# WEB DEV BUNDLE CONFIGURATION
# ========================================

# Function to setup web dev tools for a user
setup_webdev_for_user() {
    local user_home="$1"
    local username="$2"

    echo "  Setting up web dev tools for $username..."

    # Create directories
    mkdir -p "$user_home/.config"
    mkdir -p "$user_home/.local/share/bash-completion/completions"
    mkdir -p "$user_home/.local/share/zsh/site-functions"

    # Setup httpie config directory
    mkdir -p "$user_home/.config/httpie"

    # Create default httpie config if it doesn't exist
    if [ ! -f "$user_home/.config/httpie/config.json" ]; then
        cat > "$user_home/.config/httpie/config.json" << 'EOF'
{
    "default_options": [
        "--style=native",
        "--print=HhBb"
    ]
}
EOF
    fi

    # Set proper ownership
    if [ "$username" != "root" ]; then
        chown -R "$username:$username" "$user_home/.config" 2>/dev/null || true
        chown -R "$username:$username" "$user_home/.local" 2>/dev/null || true
    fi

    echo "    ✓ Web dev tools configured for $username"
}

# Get web dev aliases for shell configuration
get_webdev_aliases() {
    cat << 'EOF'
# Web development aliases
alias weather='curl -s wttr.in'
alias myip='curl -s ipinfo.io/ip'
alias json='jq .'
alias yaml='yq .'
alias serve='python3 -m http.server'
EOF
}
