#!/bin/bash -e

USERNAME="${USERNAME:-zero}"

# Install packages required for sandbox functionality
echo "Installing sandbox packages..."
apt-get update

# Use apt-fast if available, otherwise fall back to apt-get
if command -v apt-fast >/dev/null 2>&1; then
    APT_CMD="apt-fast"
else
    APT_CMD="apt-get"
fi

$APT_CMD install -y \
    ipset \
    dnsutils \
    libcap2-bin
$APT_CMD clean
rm -rf /var/lib/apt/lists/*

# Create directory for scripts
mkdir -p /usr/local/share/sandbox

# Create the firewall initialization script that will be called by init-sandbox
cat > /usr/local/share/sandbox/init-firewall.sh << 'EOF'
#!/bin/bash
set -euo pipefail

echo "Initializing sandbox firewall..."

# Check if running in container
if [ ! -f /.dockerenv ] && [ ! -f /run/.containerenv ]; then
    echo "  Warning: Not running in a container, skipping firewall setup."
    exit 0
fi

# Check if we have necessary capabilities
if ! capsh --print | grep -q cap_net_admin; then
    echo "  Warning: NET_ADMIN capability not available, skipping firewall setup."
    exit 0
fi

# Function to resolve domain to IPs
resolve_domain() {
    local domain=$1
    dig +short "$domain" A | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' || true
    dig +short "$domain" AAAA | grep -E '^[0-9a-fA-F:]+$' || true
}

# Function to expand wildcard domains to common subdomains
expand_wildcard_domain() {
    local domain=$1
    local base_domain=${domain#*.}
    local common_subdomains="www api cdn auth mail ftp blog shop store admin dashboard app dev test staging production"
    
    echo "$base_domain"
    for subdomain in $common_subdomains; do
        echo "$subdomain.$base_domain"
    done
}

# Function to add domain and its IPs to ipset
add_domain_to_ipset() {
    local domain=$1
    local domains_to_resolve
    
    if [[ $domain == *.* ]]; then
        domains_to_resolve=$(expand_wildcard_domain "$domain")
    else
        domains_to_resolve="$domain"
    fi
    
    for target_domain in $domains_to_resolve; do
        local ips=$(resolve_domain "$target_domain")
        
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
            echo "    ✓ Added IPs for $target_domain"
        fi
    done
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
)

# Add GitHub IP ranges
echo "  Adding GitHub IP ranges..."
GITHUB_META_URL="https://api.github.com/meta"
if GITHUB_IPS=$(curl -s "$GITHUB_META_URL" | grep -oE '"[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+"' | tr -d '"'); then
    for ip_range in $GITHUB_IPS; do
        sudo ipset add allowed-domains "$ip_range" 2>/dev/null || true
    done
fi

# Resolve and add core domains
echo "  Resolving core domains..."
for domain in "${CORE_DOMAINS[@]}"; do
    add_domain_to_ipset "$domain"
done

# Add additional allowed domains from environment
if [ -n "${SANDBOX_ALLOWED_DOMAINS:-}" ]; then
    IFS=',' read -ra EXTRA_DOMAINS <<< "$SANDBOX_ALLOWED_DOMAINS"
    for domain in "${EXTRA_DOMAINS[@]}"; do
        domain=$(echo "$domain" | xargs) # trim whitespace
        if [ -n "$domain" ]; then
            echo "  Adding custom domain: $domain..."
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
echo "  Configuring firewall rules..."

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

echo "    ✓ Firewall initialization complete"

# Test connectivity
echo "
Testing connectivity..."
if curl -s https://api.anthropic.com > /dev/null 2>&1; then
    echo "  ✓ Can reach Anthropic API"
else
    echo "  ✗ Cannot reach Anthropic API"
fi

if curl -s https://api.github.com > /dev/null 2>&1; then
    echo "  ✓ Can reach GitHub API"
else
    echo "  ✗ Cannot reach GitHub API"
fi

# This should fail
if curl -s --max-time 5 https://example.com > /dev/null 2>&1; then
    echo "  ✗ Firewall may not be working correctly - can reach blocked site"
else
    echo "  ✓ Firewall is blocking unauthorized connections"
fi
EOF

chmod +x /usr/local/share/sandbox/init-firewall.sh

# Add sudoers entries for sandbox operations
cat > /etc/sudoers.d/sandbox << EOF
# Sandbox state management
${USERNAME} ALL=(ALL) NOPASSWD: /bin/mkdir -p /var/lib/devcontainer-sandbox
${USERNAME} ALL=(ALL) NOPASSWD: /bin/chmod 755 /var/lib/devcontainer-sandbox
${USERNAME} ALL=(ALL) NOPASSWD: /usr/bin/tee /var/lib/devcontainer-sandbox/*
${USERNAME} ALL=(ALL) NOPASSWD: /bin/chmod 444 /var/lib/devcontainer-sandbox/*
${USERNAME} ALL=(ALL) NOPASSWD: /sbin/iptables -L OUTPUT -n

# Firewall management
${USERNAME} ALL=(ALL) NOPASSWD: /usr/local/share/sandbox/init-firewall.sh
${USERNAME} ALL=(ALL) NOPASSWD: /usr/sbin/iptables, /usr/sbin/ip6tables, /usr/sbin/ipset
EOF

chmod 0440 /etc/sudoers.d/sandbox

echo "
✓ Sandbox setup complete"