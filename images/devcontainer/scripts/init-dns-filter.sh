#!/bin/bash

set -e

echo "Initializing DNS filtering..."

# Check if DNS filtering is enabled
if [ "${DNS_FILTER_ENABLED:-false}" != "true" ]; then
    echo "  DNS filtering is disabled (DNS_FILTER_ENABLED != true)"
    exit 0
fi

# Default allowed domains (same as current sandbox defaults)
DEFAULT_ALLOWED_DOMAINS=(
    # Anthropic/Claude
    "anthropic.com"
    "*.anthropic.com"
    "claude.ai"
    "*.claude.ai"
    
    # GitHub
    "github.com"
    "*.github.com"
    "githubusercontent.com"
    "*.githubusercontent.com"
    "githubassets.com"
    "*.githubassets.com"
    
    # Package managers
    "npmjs.org"
    "*.npmjs.org"
    "yarnpkg.com"
    "*.yarnpkg.com"
    "bun.sh"
    "*.bun.sh"
    "deno.land"
    "*.deno.land"
    "deno.com"
    "*.deno.com"
    "jsr.io"
    "*.jsr.io"
    "pypi.org"
    "*.pypi.org"
    "pythonhosted.org"
    "*.pythonhosted.org"
    "rubygems.org"
    "*.rubygems.org"
    "crates.io"
    "*.crates.io"
    
    # Linear
    "linear.app"
    "*.linear.app"
    
    # Local/Private networks (CIDR notation)
    "10.0.0.0/8"
    "172.16.0.0/12"
    "192.168.0.0/16"
    "127.0.0.0/8"
    "::1/128"
    "fc00::/7"
    "fe80::/10"
)

# Parse custom allowed domains
IFS=',' read -ra CUSTOM_DOMAINS <<< "${DNS_ALLOWED_DOMAINS:-}"

# Combine default and custom domains
ALL_DOMAINS=("${DEFAULT_ALLOWED_DOMAINS[@]}")
for domain in "${CUSTOM_DOMAINS[@]}"; do
    domain=$(echo "$domain" | xargs)  # Trim whitespace
    if [ -n "$domain" ]; then
        ALL_DOMAINS+=("$domain")
    fi
done

# Generate Blocky configuration
cat > /etc/blocky/config.yml <<EOF
# Blocky DNS Filter Configuration
# Generated at $(date)

# Upstream DNS servers
upstream:
  default:
    - 1.1.1.1
    - 1.0.0.1
    - 2606:4700:4700::1111
    - 2606:4700:4700::1001

# Port configuration
ports:
  dns: 53

# Logging
log:
  level: info
  format: text
  timestamp: true

# Caching
caching:
  minTime: 5m
  maxTime: 30m
  maxItemsCount: 0
  prefetching: true
  prefetchExpires: 2h
  prefetchThreshold: 5

# Custom DNS mappings
customDNS:
  customTTL: 1h
  filterUnmappedTypes: true
  mapping:
    # Allow localhost
    localhost: 127.0.0.1

# Conditional forwarding for local domains
conditional:
  mapping:
    # Docker internal DNS
    docker.internal: 127.0.0.11

# Blocking configuration
blocking:
  blockType: nxDomain
  blockTTL: 1m
  
  # Allowlists - domains that are always allowed
  allowlists:
    default:
EOF

# Add allowed domains to configuration
for domain in "${ALL_DOMAINS[@]}"; do
    # Skip CIDR blocks for domain allowlist
    if [[ ! "$domain" =~ / ]]; then
        echo "      - |" >> /etc/blocky/config.yml
        echo "        $domain" >> /etc/blocky/config.yml
    fi
done

# Continue configuration
cat >> /etc/blocky/config.yml <<EOF

  # Default deny - block everything not explicitly allowed
  denylists:
    default:
      - |
        # Block all domains by default
        *

# Client settings
clientLookup:
  upstream: 127.0.0.1
  singleNameOrder:
    - 2
    - 1

# Performance settings
hostsFile:
  filePath: /etc/hosts
  hostsTTL: 60m
  refreshPeriod: 30m
  filterLoopback: true

# Prometheus metrics
prometheus:
  enable: false
  path: /metrics

# Health check
health:
  httpPort: 4000
EOF

# Set proper permissions
chown -R blocky:blocky /etc/blocky

# Start Blocky
echo "  Starting Blocky DNS proxy..."
if command -v systemctl &> /dev/null; then
    systemctl daemon-reload
    systemctl enable blocky
    systemctl start blocky
else
    # For containers without systemd
    su -s /bin/bash blocky -c "/usr/local/bin/blocky --config /etc/blocky/config.yml" &
    echo $! > /var/run/blocky.pid
fi

# Update resolv.conf to use local DNS
cp /etc/resolv.conf /etc/resolv.conf.backup
echo "nameserver 127.0.0.1" > /etc/resolv.conf
echo "options ndots:0" >> /etc/resolv.conf

echo "  ✓ DNS filtering initialized"
echo "  ✓ Allowed domains: ${#ALL_DOMAINS[@]}"
echo "  ✓ Wildcard support enabled (*.domain.com)"