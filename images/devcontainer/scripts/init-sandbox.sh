#!/bin/bash
# Shared sandbox initialization logic that can be called from any entrypoint

set -e

# Source common utilities - must be available
source "/usr/local/bin/common-utils.sh"

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
    sudoIf tee /etc/blocky/config.yml > /dev/null <<EOF
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
        echo "      - |" | sudoIf tee -a /etc/blocky/config.yml > /dev/null
        echo "        $domain" | sudoIf tee -a /etc/blocky/config.yml > /dev/null
    fi
done

# Continue configuration
sudoIf tee -a /etc/blocky/config.yml > /dev/null <<EOF

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
EOF

    # Set proper permissions
    sudoIf chown -R blocky:blocky /etc/blocky

    # Make configuration immutable (if filesystem supports it)
    if sudoIf chattr +i /etc/blocky/config.yml 2>/dev/null; then
        echo "      ✓ Configuration file made immutable"
    else
        echo "      ⚠ Warning: Cannot make config immutable (filesystem doesn't support chattr)"
    fi

    # Start Blocky using s6-rc (s6-overlay v3) - must be available
    echo "    🔧 Starting DNS-based sandbox..."
    
    # Check if we're running under s6-overlay
    BLOCKY_STARTED=false
    if [ -d "/run/s6/services" ] || [ -d "/run/service" ]; then
        # s6-overlay is running, use s6-rc
        # In s6-overlay v3, services are managed with s6-rc
        # Remove the down file from the service definition
        sudoIf rm -f /etc/s6-overlay/s6-rc.d/blocky/down
        # Start blocky service using s6-rc (try both PATH and /command location)
        S6_RC_CMD="s6-rc"
        if ! command -v s6-rc >/dev/null 2>&1 && [ -x "/command/s6-rc" ]; then
            S6_RC_CMD="/command/s6-rc"
        elif [ -x "/package/admin/s6-rc-0.5.6.0/command/s6-rc" ]; then
            S6_RC_CMD="/package/admin/s6-rc-0.5.6.0/command/s6-rc"
        fi
        if sudoIf $S6_RC_CMD -u change blocky 2>/dev/null; then
            echo "      ✓ Blocky started via s6-overlay"
            BLOCKY_STARTED=true
        else
            echo "      ⚠ Warning: Could not start blocky service via s6-rc"
            echo "      ⚠ DNS filtering will not be active in this session"
        fi
    else
        # s6-overlay not detected
        echo "      ⚠ Warning: s6-overlay not detected"
        echo "      ⚠ DNS filtering requires s6-overlay to be running as init"
        echo "      ⚠ Consider using 'overrideCommand: false' in devcontainer.json"
    fi
    
    # Only configure DNS if blocky was started successfully
    if [ "$BLOCKY_STARTED" = true ]; then
        # Give blocky a moment to start
        sleep 1

        # Update resolv.conf to use local DNS
        sudoIf cp /etc/resolv.conf /etc/resolv.conf.backup
        echo "nameserver 127.0.0.1" | sudoIf tee /etc/resolv.conf > /dev/null
        echo "options ndots:0" | sudoIf tee -a /etc/resolv.conf > /dev/null

        # Make resolv.conf immutable to prevent DNS bypass (if filesystem supports it)
        if sudoIf chattr +i /etc/resolv.conf 2>/dev/null; then
            echo "      ✓ resolv.conf made immutable"
        else
            echo "      ⚠ Warning: Cannot make resolv.conf immutable (filesystem doesn't support chattr)"
        fi

        echo "      ✓ DNS-based sandbox initialized"
        echo "      ✓ Allowed domains: ${#ALL_DOMAINS[@]}"
        echo "      ✓ Configuration locked (immutable)"
    fi
else
    echo "  🔓 Sandbox mode is disabled"
fi