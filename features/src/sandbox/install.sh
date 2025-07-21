#!/bin/bash
# Sandbox Network Filter Feature Installation Script
set -e

# Feature options
ALLOWED_DOMAINS="${ALLOWEDDOMAINS:-}"
BLOCKED_DOMAINS="${BLOCKEDDOMAINS:-*.facebook.com,*.twitter.com,*.instagram.com,*.tiktok.com,*.youtube.com}"
DEFAULT_POLICY="${DEFAULTPOLICY:-block}"
ALLOW_DOCKER_NETWORKS="${ALLOWDOCKERNETWORKS:-true}"
ALLOW_LOCALHOST="${ALLOWLOCALHOST:-true}"
IMMUTABLE_CONFIG="${IMMUTABLECONFIG:-true}"
LOG_BLOCKED="${LOGBLOCKED:-true}"

echo "Installing Sandbox Network Filter..."

# Install required packages
echo "Installing required packages..."
apt-get update
apt-get install -y iptables iptables-persistent dnsmasq-base bind9-dnsutils netfilter-persistent

# Create sandbox directories
mkdir -p /usr/local/share/sandbox
mkdir -p /etc/sandbox

# Create DNS filtering configuration
cat > /usr/local/share/sandbox/setup-dns-filter.sh << 'EOF'
#!/bin/bash
# Setup DNS-based domain filtering
set -e

ALLOWED_DOMAINS="$1"
BLOCKED_DOMAINS="$2"
DEFAULT_POLICY="$3"

echo "Setting up DNS-based domain filtering..."

# Create hosts file entries for blocked domains
HOSTS_FILE="/etc/hosts.sandbox"
cp /etc/hosts "$HOSTS_FILE"

# Function to add domain blocking to hosts file
block_domain() {
    local domain="$1"
    # Remove wildcard prefix for hosts file
    local host_domain="${domain#\*.}"
    
    # Add main domain and www subdomain
    echo "127.0.0.1 $host_domain" >> "$HOSTS_FILE"
    echo "127.0.0.1 www.$host_domain" >> "$HOSTS_FILE"
    
    # If it's a wildcard, add a few common subdomains
    if [[ "$domain" == *.* ]]; then
        echo "127.0.0.1 api.$host_domain" >> "$HOSTS_FILE"
        echo "127.0.0.1 m.$host_domain" >> "$HOSTS_FILE"
        echo "127.0.0.1 mobile.$host_domain" >> "$HOSTS_FILE"
    fi
}

# Process blocked domains
if [ -n "$BLOCKED_DOMAINS" ]; then
    echo "Processing blocked domains: $BLOCKED_DOMAINS"
    IFS=',' read -ra DOMAINS <<< "$BLOCKED_DOMAINS"
    for domain in "${DOMAINS[@]}"; do
        domain=$(echo "$domain" | xargs) # trim whitespace
        if [ -n "$domain" ]; then
            echo "  Blocking domain: $domain"
            block_domain "$domain"
        fi
    done
fi

# Replace system hosts file with filtered version
cp "$HOSTS_FILE" /etc/hosts

echo "DNS filtering configured"
EOF

chmod +x /usr/local/share/sandbox/setup-dns-filter.sh

# Create iptables rule management script 
cat > /usr/local/share/sandbox/setup-rules.sh << 'EOF'
#!/bin/bash
# Setup iptables rules for sandbox network filtering
set -e

ALLOW_DOCKER_NETWORKS="${1:-true}"
ALLOW_LOCALHOST="${2:-true}"
DEFAULT_POLICY="${3:-block}"
LOG_BLOCKED="${4:-true}"

echo "Setting up basic network filtering rules..."

# Clear existing sandbox rules
iptables -t filter -F SANDBOX_OUTPUT 2>/dev/null || true
iptables -t filter -X SANDBOX_OUTPUT 2>/dev/null || true

# Create sandbox chain
iptables -t filter -N SANDBOX_OUTPUT

# Allow loopback if enabled
if [ "$ALLOW_LOCALHOST" = "true" ]; then
    iptables -t filter -A SANDBOX_OUTPUT -d 127.0.0.0/8 -j ACCEPT
    iptables -t filter -A SANDBOX_OUTPUT -d ::1/128 -j ACCEPT
fi

# Allow Docker networks if enabled (critical for container communication)
if [ "$ALLOW_DOCKER_NETWORKS" = "true" ]; then
    # Docker default networks
    iptables -t filter -A SANDBOX_OUTPUT -d 172.16.0.0/12 -j ACCEPT
    iptables -t filter -A SANDBOX_OUTPUT -d 10.0.0.0/8 -j ACCEPT
    iptables -t filter -A SANDBOX_OUTPUT -d 192.168.0.0/16 -j ACCEPT
    # Allow established connections (important for Docker services)
    iptables -t filter -A SANDBOX_OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
fi

# Allow DNS queries (needed for name resolution)
iptables -t filter -A SANDBOX_OUTPUT -p udp --dport 53 -j ACCEPT
iptables -t filter -A SANDBOX_OUTPUT -p tcp --dport 53 -j ACCEPT

# Apply default policy for external traffic
if [ "$DEFAULT_POLICY" = "block" ]; then
    echo "Setting default policy to BLOCK external traffic"
    # Block external networks (not local/docker networks)
    if [ "$LOG_BLOCKED" = "true" ]; then
        iptables -t filter -A SANDBOX_OUTPUT ! -d 10.0.0.0/8 ! -d 172.16.0.0/12 ! -d 192.168.0.0/16 ! -d 127.0.0.0/8 -j LOG --log-prefix "SANDBOX_BLOCKED: " --log-level 4
    fi
    iptables -t filter -A SANDBOX_OUTPUT ! -d 10.0.0.0/8 ! -d 172.16.0.0/12 ! -d 192.168.0.0/16 ! -d 127.0.0.0/8 -j REJECT --reject-with icmp-host-unreachable
else
    echo "Setting default policy to ALLOW external traffic"
    iptables -t filter -A SANDBOX_OUTPUT -j ACCEPT
fi

# Attach to OUTPUT chain
iptables -t filter -C OUTPUT -j SANDBOX_OUTPUT 2>/dev/null || \
    iptables -t filter -A OUTPUT -j SANDBOX_OUTPUT

echo "Basic network filtering rules configured"
EOF

chmod +x /usr/local/share/sandbox/setup-rules.sh

# Create configuration file
cat > /etc/sandbox/config << EOF
# Sandbox Network Filter Configuration
ALLOWED_DOMAINS="$ALLOWED_DOMAINS"
BLOCKED_DOMAINS="$BLOCKED_DOMAINS"
DEFAULT_POLICY="$DEFAULT_POLICY"
ALLOW_DOCKER_NETWORKS="$ALLOW_DOCKER_NETWORKS"
ALLOW_LOCALHOST="$ALLOW_LOCALHOST"
IMMUTABLE_CONFIG="$IMMUTABLE_CONFIG"
LOG_BLOCKED="$LOG_BLOCKED"
EOF

# Setup initial rules and DNS filtering
/usr/local/share/sandbox/setup-dns-filter.sh "$ALLOWED_DOMAINS" "$BLOCKED_DOMAINS" "$DEFAULT_POLICY"
/usr/local/share/sandbox/setup-rules.sh "$ALLOW_DOCKER_NETWORKS" "$ALLOW_LOCALHOST" "$DEFAULT_POLICY" "$LOG_BLOCKED"

# Create startup script that runs the filtering setup
cat > /usr/local/share/sandbox/sandbox-init.sh << 'EOF'
#!/bin/bash
# Initialize sandbox network filtering on container startup
set -e

# Load configuration
if [ -f /etc/sandbox/config ]; then
    source /etc/sandbox/config
fi

# Setup DNS filtering
/usr/local/share/sandbox/setup-dns-filter.sh "$ALLOWED_DOMAINS" "$BLOCKED_DOMAINS" "$DEFAULT_POLICY"

# Setup iptables rules
/usr/local/share/sandbox/setup-rules.sh "$ALLOW_DOCKER_NETWORKS" "$ALLOW_LOCALHOST" "$DEFAULT_POLICY" "$LOG_BLOCKED"

# Make immutable if configured
if [ "$IMMUTABLE_CONFIG" = "true" ]; then
    echo "Making configuration immutable..."
    # Save current rules
    iptables-save > /etc/iptables/rules.v4
    # Make config files read-only
    chmod 444 /etc/sandbox/config
    chattr +i /etc/sandbox/config 2>/dev/null || true
    # Protect hosts file
    chattr +i /etc/hosts 2>/dev/null || true
fi

echo "Sandbox network filtering initialized"
EOF

chmod +x /usr/local/share/sandbox/sandbox-init.sh

# Save initial iptables rules
iptables-save > /etc/iptables/rules.v4

# Create service to restore rules on boot
cat > /etc/systemd/system/sandbox-network-filter.service << 'EOF'
[Unit]
Description=Sandbox Network Filter
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/share/sandbox/sandbox-init.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# Enable the service
systemctl enable sandbox-network-filter.service 2>/dev/null || true

# Make configuration immutable if requested
if [ "$IMMUTABLE_CONFIG" = "true" ]; then
    echo "Making configuration immutable..."
    chmod 444 /etc/sandbox/config
    chattr +i /etc/sandbox/config 2>/dev/null || true
fi

echo "✓ Sandbox Network Filter installed successfully"
echo "  Allowed domains: $ALLOWED_DOMAINS"
echo "  Blocked domains: $BLOCKED_DOMAINS" 
echo "  Default policy: $DEFAULT_POLICY"
echo "  Docker networks allowed: $ALLOW_DOCKER_NETWORKS"
echo "  Localhost allowed: $ALLOW_LOCALHOST"
echo "  Configuration immutable: $IMMUTABLE_CONFIG"
echo "  Logging enabled: $LOG_BLOCKED"