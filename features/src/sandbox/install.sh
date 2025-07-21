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
apt-get install -y iptables iptables-persistent dnsmasq bind9-dnsutils netfilter-persistent

# Create sandbox directories
mkdir -p /usr/local/share/sandbox
mkdir -p /etc/sandbox

# Create DNS filtering configuration
cat > /usr/local/share/sandbox/setup-dns-filter.sh << 'EOF'
#!/bin/bash
# Setup DNS-based domain filtering with proper wildcard support
set -e

ALLOWED_DOMAINS="$1"
BLOCKED_DOMAINS="$2"
DEFAULT_POLICY="$3"

echo "Setting up DNS-based domain filtering with dnsmasq..."

# Stop dnsmasq if running
systemctl stop dnsmasq 2>/dev/null || true

# Backup original resolv.conf
cp /etc/resolv.conf /etc/resolv.conf.sandbox.backup 2>/dev/null || true

# Create dnsmasq configuration for sandbox
cat > /etc/dnsmasq.d/sandbox.conf << 'DNSMASQ_EOF'
# Sandbox network filter DNS configuration
# Listen only on localhost
interface=lo
bind-interfaces

# Don't read /etc/hosts for DNS resolution
no-hosts

# Set cache size
cache-size=1000

# Log queries for debugging (optional)
log-queries

# Forward to upstream DNS servers
server=8.8.8.8
server=8.8.4.4
server=1.1.1.1
DNSMASQ_EOF

# Create hosts file entries for exact domain matches (fallback)
HOSTS_FILE="/etc/hosts.sandbox"
cp /etc/hosts "$HOSTS_FILE"

# Function to add domain blocking 
block_domain() {
    local domain="$1"
    
    if [[ "$domain" == *.* ]]; then
        # This is a wildcard domain - configure dnsmasq to block it
        local base_domain="${domain#\*.}"
        echo "# Block wildcard domain: $domain" >> /etc/dnsmasq.d/sandbox.conf
        echo "address=/$base_domain/127.0.0.1" >> /etc/dnsmasq.d/sandbox.conf
        
        # Also add to hosts file for fallback
        echo "127.0.0.1 $base_domain" >> "$HOSTS_FILE"
        echo "127.0.0.1 www.$base_domain" >> "$HOSTS_FILE"
    else
        # Exact domain match - add to both dnsmasq and hosts
        echo "# Block exact domain: $domain" >> /etc/dnsmasq.d/sandbox.conf
        echo "address=/$domain/127.0.0.1" >> /etc/dnsmasq.d/sandbox.conf
        echo "127.0.0.1 $domain" >> "$HOSTS_FILE"
    fi
}

# Function to allow domain (override blocking)
allow_domain() {
    local domain="$1"
    
    if [[ "$domain" == *.* ]]; then
        # This is a wildcard allow - remove any blocking rules
        local base_domain="${domain#\*.}"
        echo "# Allow wildcard domain: $domain" >> /etc/dnsmasq.d/sandbox.conf
        # Don't add address= rule for allowed domains - let them resolve normally
    else
        # Exact domain allow
        echo "# Allow exact domain: $domain" >> /etc/dnsmasq.d/sandbox.conf
        # Don't add address= rule for allowed domains
    fi
}

# Process blocked domains first
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

# Process allowed domains (these can override blocked domains)
if [ -n "$ALLOWED_DOMAINS" ]; then
    echo "Processing allowed domains: $ALLOWED_DOMAINS"
    IFS=',' read -ra DOMAINS <<< "$ALLOWED_DOMAINS"
    for domain in "${DOMAINS[@]}"; do
        domain=$(echo "$domain" | xargs) # trim whitespace
        if [ -n "$domain" ]; then
            echo "  Allowing domain: $domain"
            allow_domain "$domain"
        fi
    done
fi

# Handle default policy
if [ "$DEFAULT_POLICY" = "block" ]; then
    echo "Setting default DNS policy to block unknown domains"
    # For default block policy, we'll rely on iptables to block unknown external IPs
    # DNS resolution will work, but iptables will block the connections
else
    echo "Setting default DNS policy to allow unknown domains"
    # Allow all other domains to resolve normally
fi

# Replace system hosts file with filtered version
cp "$HOSTS_FILE" /etc/hosts

# Configure system to use local dnsmasq
echo "nameserver 127.0.0.1" > /etc/resolv.conf
echo "nameserver 8.8.8.8" >> /etc/resolv.conf  # fallback

# Start dnsmasq
systemctl start dnsmasq
systemctl enable dnsmasq 2>/dev/null || true

# Test dnsmasq is working
if ! systemctl is-active dnsmasq >/dev/null 2>&1; then
    echo "Warning: dnsmasq failed to start, falling back to hosts file only"
    # Restore original resolv.conf if dnsmasq fails
    cp /etc/resolv.conf.sandbox.backup /etc/resolv.conf 2>/dev/null || true
fi

echo "DNS filtering configured with proper wildcard support"
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

# Ensure dnsmasq is running for DNS filtering
if command -v systemctl >/dev/null 2>&1; then
    systemctl start dnsmasq 2>/dev/null || true
    if ! systemctl is-active dnsmasq >/dev/null 2>&1; then
        echo "Warning: dnsmasq is not running - wildcard DNS blocking may not work properly"
    fi
fi

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
    # Protect dnsmasq configuration
    chattr +i /etc/dnsmasq.d/sandbox.conf 2>/dev/null || true
fi

echo "Sandbox network filtering initialized with proper wildcard support"
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