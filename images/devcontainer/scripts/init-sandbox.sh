#!/bin/bash
# Shared sandbox initialization logic that can be called from any entrypoint

set -e

# Source common utilities from runtime location
if [ -f "/usr/local/bin/common-utils.sh" ]; then
    source "/usr/local/bin/common-utils.sh"
else
    # Fallback for build-time usage
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -f "$SCRIPT_DIR/../../base/scripts/common-utils.sh" ]; then
        source "$SCRIPT_DIR/../../base/scripts/common-utils.sh"
    fi
fi

# Define the state file location (only writable by root)
SANDBOX_STATE_FILE="/var/lib/devcontainer-sandbox/enabled"
SANDBOX_STATE_DIR=$(dirname "$SANDBOX_STATE_FILE")

# Function to initialize sandbox state on first run
initialize_sandbox_state() {
    # Only root can create this directory and file
    if [ ! -d "$SANDBOX_STATE_DIR" ]; then
        sudoIf mkdir -p "$SANDBOX_STATE_DIR"
        sudoIf chmod 755 "$SANDBOX_STATE_DIR"  # Allow everyone to read the directory
    fi
    
    # Write the initial state based on environment variable
    # This happens only once when the container starts
    if [ ! -f "$SANDBOX_STATE_FILE" ]; then
        if [ "${SANDBOX_ENABLED}" = "true" ]; then
            echo "true" | sudoIf tee "$SANDBOX_STATE_FILE" > /dev/null
            sudoIf chmod 444 "$SANDBOX_STATE_FILE"  # Read-only for everyone, owned by root
            
            # Also save allowed domains config
            echo "${SANDBOX_ALLOWED_DOMAINS:-}" | sudoIf tee "${SANDBOX_STATE_DIR}/domains" > /dev/null
            sudoIf chmod 444 "${SANDBOX_STATE_DIR}/domains"
        else
            echo "false" | sudoIf tee "$SANDBOX_STATE_FILE" > /dev/null
            sudoIf chmod 444 "$SANDBOX_STATE_FILE"
        fi
    fi
}

# Read the immutable sandbox state
read_sandbox_state() {
    if [ -f "$SANDBOX_STATE_FILE" ]; then
        cat "$SANDBOX_STATE_FILE"
    else
        echo "false"
    fi
}

# Initialize sandbox state
initialize_sandbox_state

# Check the immutable state file
SANDBOX_ENABLED=$(read_sandbox_state)

if [ "$SANDBOX_ENABLED" = "true" ]; then
    echo "  🔒 Sandbox mode is enabled (immutable)"
    
    # Read allowed domains from immutable state
    SANDBOX_ALLOWED_DOMAINS=$(cat "${SANDBOX_STATE_DIR}/domains" 2>/dev/null || echo "")
    if [ -n "$SANDBOX_ALLOWED_DOMAINS" ]; then
        export SANDBOX_ALLOWED_DOMAINS
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
    IFS=',' read -ra CUSTOM_DOMAINS <<< "${SANDBOX_ALLOWED_DOMAINS:-}"

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

    # Make configuration immutable
    chattr +i /etc/blocky/config.yml 2>/dev/null || true

    # Start Blocky
    echo "    🔧 Starting DNS-based sandbox..."
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

    # Make resolv.conf immutable to prevent DNS bypass
    chattr +i /etc/resolv.conf 2>/dev/null || true

    echo "      ✓ DNS-based sandbox initialized"
    echo "      ✓ Allowed domains: ${#ALL_DOMAINS[@]}"
    echo "      ✓ Configuration locked (immutable)"
else
    echo "  🔓 Sandbox mode is disabled"
fi