#!/bin/bash -e

# Feature options
ENABLE_FIREWALL="${ENABLEFIREWALL:-"true"}"
ADDITIONAL_ALLOWED_DOMAINS="${ADDITIONALALLOWEDDOMAINS:-""}"
PERSISTENT_VOLUMES="${PERSISTENTVOLUMES:-"true"}"
USERNAME="${USER:-"${_REMOTE_USER:-"zero"}"}"

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# Determine the appropriate non-root user
if [ "${USERNAME}" = "auto" ] || [ "${USERNAME}" = "automatic" ]; then
    USERNAME=""
    POSSIBLE_USERS=("zero" "node" "codespace" "$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd)")
    for CURRENT_USER in "${POSSIBLE_USERS[@]}"; do
        if id -u ${CURRENT_USER} > /dev/null 2>&1; then
            USERNAME=${CURRENT_USER}
            break
        fi
    done
    if [ "${USERNAME}" = "" ]; then
        USERNAME=root
    fi
elif [ "${USERNAME}" = "none" ] || ! id -u ${USERNAME} > /dev/null 2>&1; then
    USERNAME=root
fi

apt_get_update()
{
    if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
        echo "Running apt-get update..."
        apt-get update -y
    fi
}

# Checks if packages are installed and installs them if not
check_packages() {
    if ! dpkg -s "$@" > /dev/null 2>&1; then
        apt_get_update
        apt-get -y install --no-install-recommends "$@"
    fi
}

# Install required packages for firewall functionality
if [ "${ENABLE_FIREWALL}" = "true" ]; then
    echo "Installing firewall dependencies..."
    check_packages iptables ipset dnsutils curl sudo
fi

# Create directory for scripts
mkdir -p /usr/local/share/claude-code

# Create the firewall initialization script
if [ "${ENABLE_FIREWALL}" = "true" ]; then
    echo "Setting up firewall initialization script..."
    
    cat > /usr/local/share/claude-code/init-firewall.sh << 'EOF'
#!/bin/bash
set -euo pipefail

echo "Initializing Claude Code sandbox firewall..."

# Check if running in container
if [ ! -f /.dockerenv ] && [ ! -f /run/.containerenv ]; then
    echo "Not running in a container, skipping firewall setup"
    exit 0
fi

# Check if we have necessary capabilities
if ! capsh --print | grep -q cap_net_admin; then
    echo "Warning: NET_ADMIN capability not available, skipping firewall setup"
    exit 0
fi

# Function to resolve domain to IPs
resolve_domain() {
    local domain=$1
    dig +short "$domain" A | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' || true
    dig +short "$domain" AAAA | grep -E '^[0-9a-fA-F:]+$' || true
}

# Function to add domain and its IPs to ipset
add_domain_to_ipset() {
    local domain=$1
    local ips=$(resolve_domain "$domain")
    
    if [ -n "$ips" ]; then
        for ip in $ips; do
            if [[ $ip =~ : ]]; then
                # IPv6
                sudo ipset add allowed-domains-v6 "$ip" 2>/dev/null || true
            else
                # IPv4
                sudo ipset add allowed-domains "$ip" 2>/dev/null || true
            fi
        done
        echo "Added IPs for $domain"
    fi
}

# Create ipsets for allowed domains
sudo ipset create allowed-domains hash:net family inet -exist
sudo ipset create allowed-domains-v6 hash:net family inet6 -exist

# Core domains to allow
CORE_DOMAINS=(
    # Anthropic/Claude
    "anthropic.com"
    "www.anthropic.com"
    "api.anthropic.com"
    "claude.ai"
    "www.claude.ai"
    
    # GitHub
    "github.com"
    "api.github.com"
    "raw.githubusercontent.com"
    "objects.githubusercontent.com"
    "codeload.github.com"
    "github.githubassets.com"
    "collector.github.com"
    
    # Package managers
    "registry.npmjs.org"
    "registry.yarnpkg.com"
    "bun.sh"
    "install.bun.sh"
    "deno.land"
    "deno.com"
    "jsr.io"
    "pypi.org"
    "files.pythonhosted.org"
    "rubygems.org"
    "crates.io"
    "static.crates.io"
    
    # Linear
    "linear.app"
    "api.linear.app"
    "cdn.linear.app"
    
    # Other development tools
    "dl.google.com"
    "storage.googleapis.com"
)

# Add GitHub IP ranges
echo "Adding GitHub IP ranges..."
GITHUB_META_URL="https://api.github.com/meta"
if GITHUB_IPS=$(curl -s "$GITHUB_META_URL" | grep -oE '"[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+"' | tr -d '"'); then
    for ip_range in $GITHUB_IPS; do
        sudo ipset add allowed-domains "$ip_range" 2>/dev/null || true
    done
fi

# Resolve and add core domains
echo "Resolving core domains..."
for domain in "${CORE_DOMAINS[@]}"; do
    add_domain_to_ipset "$domain"
done

# Add additional allowed domains from environment
if [ -n "${ADDITIONAL_ALLOWED_DOMAINS:-}" ]; then
    IFS=',' read -ra EXTRA_DOMAINS <<< "$ADDITIONAL_ALLOWED_DOMAINS"
    for domain in "${EXTRA_DOMAINS[@]}"; do
        domain=$(echo "$domain" | xargs) # trim whitespace
        if [ -n "$domain" ]; then
            echo "Adding custom domain: $domain"
            add_domain_to_ipset "$domain"
        fi
    done
fi

# Add local/private IP ranges
sudo ipset add allowed-domains 10.0.0.0/8 2>/dev/null || true
sudo ipset add allowed-domains 172.16.0.0/12 2>/dev/null || true
sudo ipset add allowed-domains 192.168.0.0/16 2>/dev/null || true
sudo ipset add allowed-domains 127.0.0.0/8 2>/dev/null || true

# Configure iptables rules
echo "Configuring firewall rules..."

# Save current rules
sudo iptables-save > /tmp/iptables.backup
sudo ip6tables-save > /tmp/ip6tables.backup

# Set default policies
sudo iptables -P INPUT ACCEPT
sudo iptables -P FORWARD DROP
sudo iptables -P OUTPUT DROP

sudo ip6tables -P INPUT ACCEPT
sudo ip6tables -P FORWARD DROP
sudo ip6tables -P OUTPUT DROP

# Allow all loopback traffic
sudo iptables -A OUTPUT -o lo -j ACCEPT
sudo ip6tables -A OUTPUT -o lo -j ACCEPT

# Allow established connections
sudo iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
sudo ip6tables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow DNS queries
sudo iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
sudo iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT
sudo ip6tables -A OUTPUT -p udp --dport 53 -j ACCEPT
sudo ip6tables -A OUTPUT -p tcp --dport 53 -j ACCEPT

# Allow traffic to ipset domains
sudo iptables -A OUTPUT -m set --match-set allowed-domains dst -j ACCEPT
sudo ip6tables -A OUTPUT -m set --match-set allowed-domains-v6 dst -j ACCEPT

# Log dropped packets (optional, can be verbose)
# sudo iptables -A OUTPUT -j LOG --log-prefix "DROPPED: " --log-level 4

echo "Firewall initialization complete"

# Test connectivity
echo "Testing connectivity..."
if curl -s https://api.anthropic.com > /dev/null 2>&1; then
    echo "✓ Can reach Anthropic API"
else
    echo "✗ Cannot reach Anthropic API"
fi

if curl -s https://api.github.com > /dev/null 2>&1; then
    echo "✓ Can reach GitHub API"
else
    echo "✗ Cannot reach GitHub API"
fi

# This should fail
if curl -s --max-time 5 https://example.com > /dev/null 2>&1; then
    echo "✗ Firewall may not be working correctly - can reach blocked site"
else
    echo "✓ Firewall is blocking unauthorized connections"
fi
EOF

    chmod +x /usr/local/share/claude-code/init-firewall.sh
    
    # Add sudoers entry for the user to run firewall script
    if [ "${USERNAME}" != "root" ]; then
        echo "${USERNAME} ALL=(ALL) NOPASSWD: /usr/local/share/claude-code/init-firewall.sh" > /etc/sudoers.d/claude-code
        echo "${USERNAME} ALL=(ALL) NOPASSWD: /usr/sbin/iptables, /usr/sbin/ip6tables, /usr/sbin/ipset" >> /etc/sudoers.d/claude-code
        chmod 0440 /etc/sudoers.d/claude-code
    fi
    
    # Pass environment variables to the script
    if [ -n "${ADDITIONAL_ALLOWED_DOMAINS}" ]; then
        echo "export ADDITIONAL_ALLOWED_DOMAINS=\"${ADDITIONAL_ALLOWED_DOMAINS}\"" >> /etc/profile.d/claude-code.sh
    fi
fi

# Create volume directories if they don't exist (for bind mounts)
if [ "${PERSISTENT_VOLUMES}" = "true" ] && [ "${USERNAME}" != "root" ]; then
    echo "Setting up persistent volume directories..."
    
    # Create directories if they don't exist
    USER_HOME=$(getent passwd ${USERNAME} | cut -d: -f6)
    
    mkdir -p "${USER_HOME}/.claude"
    mkdir -p "${USER_HOME}/.anthropic"
    mkdir -p "${USER_HOME}/.config/claude-code"
    
    # Set ownership
    chown -R ${USERNAME}:${USERNAME} "${USER_HOME}/.claude"
    chown -R ${USERNAME}:${USERNAME} "${USER_HOME}/.anthropic"
    chown -R ${USERNAME}:${USERNAME} "${USER_HOME}/.config/claude-code"
fi

# Install claude-code CLI via npm if npm is available
echo "Installing claude-code CLI..."
if command -v npm &> /dev/null; then
    # Install globally as root, then ensure correct permissions
    npm install -g claude-code
    
    # Get the global npm prefix
    NPM_PREFIX=$(npm config get prefix)
    
    # If not running as root user, ensure the user has access
    if [ "${USERNAME}" != "root" ]; then
        # Ensure the user owns their npm directory
        if [ -d "${USER_HOME}/.npm" ]; then
            chown -R ${USERNAME}:${USERNAME} "${USER_HOME}/.npm"
        fi
    fi
    
    echo "Claude Code CLI installed successfully"
else
    echo "Warning: npm not found. Claude Code CLI not installed."
    echo "To install claude-code later, run: npm install -g claude-code"
fi

echo "Claude Code feature installation complete!"