#!/bin/bash
set -e

# ========================================
# NETWORKING BUNDLE INSTALLATION
# ========================================

install_networking_bundle() {
    echo "🌐 Installing networking bundle..."

    # Install core networking tools
    local networking_packages="openssh-client iproute2 net-tools netcat-openbsd nmap rsync wget curl dnsutils iputils-ping telnet tcpdump traceroute whois socat iperf3"

    # Install packages
    apt-get install -y $networking_packages

    echo "✓ Networking bundle installed"
}

# ========================================
# NETWORKING BUNDLE CONFIGURATION
# ========================================

# Function to setup networking tools for a user
setup_networking_for_user() {
    local user_home="$1"
    local username="$2"

    echo "  Setting up networking tools for $username..."

    # Create directories
    mkdir -p "$user_home/.config"
    mkdir -p "$user_home/.ssh"

    # Create basic SSH config if it doesn't exist
    if [ ! -f "$user_home/.ssh/config" ]; then
        cat > "$user_home/.ssh/config" << 'EOF'
# SSH Configuration
Host *
    ServerAliveInterval 60
    ServerAliveCountMax 3
    ControlMaster auto
    ControlPath ~/.ssh/sockets/ssh_mux_%h_%p_%r
    ControlPersist 10m

# Create socket directory
Host *
    PermitLocalCommand yes
    LocalCommand mkdir -p ~/.ssh/sockets
EOF
        chmod 600 "$user_home/.ssh/config"
    fi

    # Create SSH sockets directory
    mkdir -p "$user_home/.ssh/sockets"
    chmod 700 "$user_home/.ssh/sockets"

    # Set proper ownership
    if [ "$username" != "root" ]; then
        chown -R "$username:$username" "$user_home/.ssh" 2>/dev/null || true
        chown -R "$username:$username" "$user_home/.config" 2>/dev/null || true
    fi

    echo "    ✓ Networking tools configured for $username"
}

# Get networking aliases for shell configuration
get_networking_aliases() {
    cat << 'EOF'
# Network aliases
alias ports='netstat -tuln'
alias listening='lsof -i -P | grep LISTEN'
alias myip='curl -s ipinfo.io/ip'
alias speedtest='curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python3 -'
alias ping8='ping 8.8.8.8'
alias flushdns='sudo systemctl flush-dns'
alias netinfo='ip addr show'
alias netroute='ip route show'
EOF
}
