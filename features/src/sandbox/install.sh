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
apt-get install -y iptables iptables-persistent dnsutils netfilter-persistent

# Create sandbox directories
mkdir -p /usr/local/share/sandbox
mkdir -p /etc/sandbox

# Create domain resolver script
cat > /usr/local/share/sandbox/domain-resolver.sh << 'EOF'
#!/bin/bash
# Domain to IP resolution with caching
set -e

CACHE_DIR="/var/cache/sandbox-domains"
mkdir -p "$CACHE_DIR"

resolve_domain() {
    local domain="$1"
    local cache_file="$CACHE_DIR/${domain}"
    
    # Remove wildcard prefix for resolution
    local resolve_domain="${domain#\*.}"
    
    # Check cache (valid for 1 hour)
    if [ -f "$cache_file" ] && [ $(($(date +%s) - $(stat -c %Y "$cache_file"))) -lt 3600 ]; then
        cat "$cache_file"
        return
    fi
    
    # Resolve domain to IPs
    local ips=$(dig +short "$resolve_domain" A | grep -E '^[0-9.]+$' | sort -u)
    if [ -n "$ips" ]; then
        echo "$ips" | tee "$cache_file"
    fi
}

# Main resolver function
case "$1" in
    resolve)
        resolve_domain "$2"
        ;;
    clear-cache)
        rm -rf "$CACHE_DIR"/*
        echo "Cache cleared"
        ;;
    *)
        echo "Usage: $0 {resolve|clear-cache} [domain]"
        exit 1
        ;;
esac
EOF

chmod +x /usr/local/share/sandbox/domain-resolver.sh

# Create iptables rule management script
cat > /usr/local/share/sandbox/setup-rules.sh << 'EOF'
#!/bin/bash
# Setup iptables rules for sandbox network filtering
set -e

ALLOWED_DOMAINS="${1:-}"
BLOCKED_DOMAINS="${2:-}"
DEFAULT_POLICY="${3:-block}"
ALLOW_DOCKER_NETWORKS="${4:-true}"
ALLOW_LOCALHOST="${5:-true}"
LOG_BLOCKED="${6:-true}"

echo "Setting up sandbox network filtering rules..."

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

# Allow Docker networks if enabled
if [ "$ALLOW_DOCKER_NETWORKS" = "true" ]; then
    # Docker default networks
    iptables -t filter -A SANDBOX_OUTPUT -d 172.16.0.0/12 -j ACCEPT
    iptables -t filter -A SANDBOX_OUTPUT -d 10.0.0.0/8 -j ACCEPT
    iptables -t filter -A SANDBOX_OUTPUT -d 192.168.0.0/16 -j ACCEPT
    # Docker bridge network
    iptables -t filter -A SANDBOX_OUTPUT -o docker0 -j ACCEPT
fi

# Process allowed domains
if [ -n "$ALLOWED_DOMAINS" ]; then
    echo "Processing allowed domains: $ALLOWED_DOMAINS"
    IFS=',' read -ra DOMAINS <<< "$ALLOWED_DOMAINS"
    for domain in "${DOMAINS[@]}"; do
        domain=$(echo "$domain" | xargs) # trim whitespace
        if [ -n "$domain" ]; then
            echo "  Allowing domain: $domain"
            ips=$(/usr/local/share/sandbox/domain-resolver.sh resolve "$domain" 2>/dev/null || true)
            if [ -n "$ips" ]; then
                while IFS= read -r ip; do
                    if [ -n "$ip" ]; then
                        iptables -t filter -A SANDBOX_OUTPUT -d "$ip" -j ACCEPT
                    fi
                done <<< "$ips"
            fi
        fi
    done
fi

# Process blocked domains  
if [ -n "$BLOCKED_DOMAINS" ]; then
    echo "Processing blocked domains: $BLOCKED_DOMAINS"
    IFS=',' read -ra DOMAINS <<< "$BLOCKED_DOMAINS"
    for domain in "${DOMAINS[@]}"; do
        domain=$(echo "$domain" | xargs) # trim whitespace
        if [ -n "$domain" ]; then
            echo "  Blocking domain: $domain"
            ips=$(/usr/local/share/sandbox/domain-resolver.sh resolve "$domain" 2>/dev/null || true)
            if [ -n "$ips" ]; then
                while IFS= read -r ip; do
                    if [ -n "$ip" ]; then
                        if [ "$LOG_BLOCKED" = "true" ]; then
                            iptables -t filter -A SANDBOX_OUTPUT -d "$ip" -j LOG --log-prefix "SANDBOX_BLOCKED: " --log-level 4
                        fi
                        iptables -t filter -A SANDBOX_OUTPUT -d "$ip" -j REJECT --reject-with icmp-host-unreachable
                    fi
                done <<< "$ips"
            fi
        fi
    done
fi

# Apply default policy
if [ "$DEFAULT_POLICY" = "block" ]; then
    echo "Setting default policy to BLOCK"
    if [ "$LOG_BLOCKED" = "true" ]; then
        iptables -t filter -A SANDBOX_OUTPUT -j LOG --log-prefix "SANDBOX_DEFAULT_BLOCKED: " --log-level 4
    fi
    iptables -t filter -A SANDBOX_OUTPUT -j REJECT --reject-with icmp-host-unreachable
else
    echo "Setting default policy to ALLOW"
    iptables -t filter -A SANDBOX_OUTPUT -j ACCEPT
fi

# Attach to OUTPUT chain
iptables -t filter -C OUTPUT -j SANDBOX_OUTPUT 2>/dev/null || \
    iptables -t filter -A OUTPUT -j SANDBOX_OUTPUT

echo "Sandbox network filtering rules configured"
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

# Setup initial rules
/usr/local/share/sandbox/setup-rules.sh "$ALLOWED_DOMAINS" "$BLOCKED_DOMAINS" "$DEFAULT_POLICY" "$ALLOW_DOCKER_NETWORKS" "$ALLOW_LOCALHOST" "$LOG_BLOCKED"

# Create startup script that runs the rules setup
cat > /usr/local/share/sandbox/sandbox-init.sh << 'EOF'
#!/bin/bash
# Initialize sandbox network filtering on container startup
set -e

# Load configuration
if [ -f /etc/sandbox/config ]; then
    source /etc/sandbox/config
fi

# Setup rules
/usr/local/share/sandbox/setup-rules.sh "$ALLOWED_DOMAINS" "$BLOCKED_DOMAINS" "$DEFAULT_POLICY" "$ALLOW_DOCKER_NETWORKS" "$ALLOW_LOCALHOST" "$LOG_BLOCKED"

# Make immutable if configured
if [ "$IMMUTABLE_CONFIG" = "true" ]; then
    echo "Making iptables configuration immutable..."
    # Save current rules
    iptables-save > /etc/iptables/rules.v4
    # Make config files read-only
    chmod 444 /etc/sandbox/config
    chattr +i /etc/sandbox/config 2>/dev/null || true
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