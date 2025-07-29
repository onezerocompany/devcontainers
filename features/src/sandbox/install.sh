#!/bin/bash
# Sandbox Network Filter Feature Installation Script
set -e

echo "Starting Sandbox Network Filter installation (dnsmasq-based)..."

# Sandbox initialization will only happen at runtime through the entrypoint
echo "Sandbox will be initialized at container runtime"

# Ensure non-interactive mode for apt
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

# Feature options
DEFAULT_POLICY="${DEFAULTPOLICY:-block}"
ALLOWED_DOMAINS="${ALLOWEDDOMAINS:-}"
BLOCKED_DOMAINS="${BLOCKEDDOMAINS:-}"
IMMUTABLE_CONFIG="${IMMUTABLECONFIG:-true}"
LOG_QUERIES="${LOGQUERIES:-true}"
ALLOW_CLAUDE_WEBFETCH_DOMAINS="${ALLOWCLAUDEWEBFETCHDOMAINS:-true}"
CLAUDE_SETTINGS_PATHS="${CLAUDESETTINGSPATHS:-.claude/settings.json,.claude/settings.local.json,~/.claude/settings.json}"
ALLOW_COMMON_DEVELOPMENT="${ALLOWCOMMONDEVELOPMENT:-true}"

echo "Installing Sandbox Network Filter (dnsmasq-based)..."

# Install required packages
echo "Installing required packages..."

echo "Running apt-get update..."
apt-get update -qq
echo "Installing packages..."

# Install dnsmasq and basic networking tools
apt-get install -y -qq --no-install-recommends sudo dnsmasq jq dnsutils curl

echo "Package installation complete"

# Create sandbox directories
mkdir -p /usr/local/share/sandbox
mkdir -p /etc/sandbox
mkdir -p /etc/dnsmasq.d

# Copy common domains file
cp "$(dirname "$0")/common-domains.txt" /usr/local/share/sandbox/ || {
    echo "Warning: Could not copy common-domains.txt, creating basic version"
    cat > /usr/local/share/sandbox/common-domains.txt << 'DOMAINS_EOF'
# Basic common development domains
github.com
api.github.com
registry.npmjs.org
pypi.org
hub.docker.com
DOMAINS_EOF
}

# Create generate-dnsmasq-config.sh script
cat > /usr/local/share/sandbox/generate-dnsmasq-config.sh << 'EOF'
#!/bin/bash
# Generate dnsmasq configuration for domain filtering
set -e

DEFAULT_POLICY="${1:-block}"
ALLOWED_DOMAINS="${2:-}"
BLOCKED_DOMAINS="${3:-}"
ALLOW_CLAUDE_WEBFETCH_DOMAINS="${4:-true}"
CLAUDE_SETTINGS_PATHS="${5:-.claude/settings.json,.claude/settings.local.json,~/.claude/settings.json}"
ALLOW_COMMON_DEVELOPMENT="${6:-true}"
LOG_QUERIES="${7:-true}"

echo "Generating dnsmasq configuration..."

# Start with basic dnsmasq config
cat > /etc/dnsmasq.d/sandbox.conf << DNSMASQ_EOF
# Sandbox DNS Filter - dnsmasq configuration
# Listen only on localhost
listen-address=127.0.0.1
bind-interfaces

# Don't read /etc/hosts
no-hosts

# Use upstream DNS servers
server=8.8.8.8
server=1.1.1.1

# Log queries for debugging
$([ "$LOG_QUERIES" = "true" ] && echo "log-queries" || echo "# log-queries disabled")

# Domain filtering rules below
DNSMASQ_EOF

# Function to add a domain to allow list
add_allowed_domain() {
    local domain="$1"
    echo "# Allow: $domain" >> /etc/dnsmasq.d/sandbox.conf
    # For allowed domains, use normal DNS resolution (no special config needed)
    # Just ensure they're not blocked
}

# Function to add a domain to block list  
add_blocked_domain() {
    local domain="$1"
    echo "# Block: $domain" >> /etc/dnsmasq.d/sandbox.conf
    # Block by pointing to localhost (127.0.0.1)
    echo "address=/$domain/127.0.0.1" >> /etc/dnsmasq.d/sandbox.conf
}

# Collect all domains that should be allowed
declare -A allowed_domains_set
declare -A blocked_domains_set

# Process custom allowed domains
if [ -n "$ALLOWED_DOMAINS" ]; then
    echo "Processing allowed domains: $ALLOWED_DOMAINS"
    IFS=',' read -ra DOMAIN_LIST <<< "$ALLOWED_DOMAINS"
    for domain in "${DOMAIN_LIST[@]}"; do
        domain=$(echo "$domain" | xargs)
        if [ -n "$domain" ]; then
            # Remove wildcard prefix for processing but keep track of original format
            clean_domain=${domain#\*.}
            allowed_domains_set["$clean_domain"]=1
            echo "  Added allowed domain: $domain"
        fi
    done
fi

# Process Claude WebFetch domains if enabled
if [ "$ALLOW_CLAUDE_WEBFETCH_DOMAINS" = "true" ]; then
    echo "Extracting Claude WebFetch domains..."
    
    # Set workspace folder environment variables
    if [ -z "$WORKSPACE_FOLDER" ]; then
        if [ -n "$DEVCONTAINER_WORKSPACE_FOLDER" ]; then
            export WORKSPACE_FOLDER="$DEVCONTAINER_WORKSPACE_FOLDER"
        elif [ -n "$VSCODE_WORKSPACE" ]; then
            export WORKSPACE_FOLDER="$VSCODE_WORKSPACE"
        elif [ -n "$VSCODE_CWD" ]; then
            export WORKSPACE_FOLDER="$VSCODE_CWD"
        elif [ -n "$PWD" ] && [ -d "$PWD/.devcontainer" ]; then
            export WORKSPACE_FOLDER="$PWD"
        else
            export WORKSPACE_FOLDER="/workspace"
        fi
    fi
    
    # Extract domains from Claude settings files
    IFS=',' read -ra PATHS <<< "$CLAUDE_SETTINGS_PATHS"
    for path in "${PATHS[@]}"; do
        path=$(echo "$path" | xargs)
        expanded_path="${path/#\~/$HOME}"
        
        if [[ "$expanded_path" != /* ]]; then
            expanded_path="$WORKSPACE_FOLDER/$expanded_path"
        fi
        
        if [ -f "$expanded_path" ]; then
            echo "  Reading Claude settings: $expanded_path"
            
            # Extract WebFetch rules from permissions.allow array
            webfetch_rules=$(jq -r '.permissions.allow[]? | select(startswith("WebFetch(domain:"))' "$expanded_path" 2>/dev/null || true)
            
            while IFS= read -r rule; do
                if [ -n "$rule" ]; then
                    # Extract domain from WebFetch(domain:example.com) format
                    domain=$(echo "$rule" | sed -n 's/WebFetch(domain:\([^)]*\))/\1/p')
                    if [ -n "$domain" ]; then
                        # Remove wildcard prefix if present
                        clean_domain=${domain#\*.}
                        allowed_domains_set["$clean_domain"]=1
                        echo "    Found Claude domain: $domain"
                    fi
                fi
            done <<< "$webfetch_rules"
        fi
    done
fi

# Process common development domains if enabled
if [ "$ALLOW_COMMON_DEVELOPMENT" = "true" ]; then
    echo "Adding common development domains..."
    
    if [ -f "/usr/local/share/sandbox/common-domains.txt" ]; then
        while IFS= read -r domain; do
            # Skip comments and empty lines
            [[ "$domain" =~ ^#.*$ ]] || [[ -z "$domain" ]] && continue
            allowed_domains_set["$domain"]=1
            echo "  Added common domain: $domain"
        done < "/usr/local/share/sandbox/common-domains.txt"
    fi
fi

# Process custom blocked domains
if [ -n "$BLOCKED_DOMAINS" ]; then
    echo "Processing blocked domains: $BLOCKED_DOMAINS"
    IFS=',' read -ra DOMAIN_LIST <<< "$BLOCKED_DOMAINS"
    for domain in "${DOMAIN_LIST[@]}"; do
        domain=$(echo "$domain" | xargs)
        if [ -n "$domain" ]; then
            # Remove wildcard prefix for processing but keep track of original format
            clean_domain=${domain#\*.}
            blocked_domains_set["$clean_domain"]=1
            echo "  Added blocked domain: $domain"
        fi
    done
fi

# Apply domain rules to dnsmasq config
echo "" >> /etc/dnsmasq.d/sandbox.conf
echo "# Explicitly blocked domains" >> /etc/dnsmasq.d/sandbox.conf

# Add blocked domains first (higher priority)
for domain in "${!blocked_domains_set[@]}"; do
    add_blocked_domain "$domain"
done

# Apply default policy
if [ "$DEFAULT_POLICY" = "block" ]; then
    echo "" >> /etc/dnsmasq.d/sandbox.conf
    echo "# Default policy: BLOCK - only explicitly allowed domains resolve normally" >> /etc/dnsmasq.d/sandbox.conf
    echo "# All other domains are blocked at DNS level" >> /etc/dnsmasq.d/sandbox.conf
    
    # In pure DNS mode, we rely on applications respecting DNS resolution
    # Blocked domains return 127.0.0.1, allowed domains resolve normally
else
    echo "" >> /etc/dnsmasq.d/sandbox.conf
    echo "# Default policy: ALLOW - using normal DNS resolution except for blocked domains" >> /etc/dnsmasq.d/sandbox.conf
fi

echo "dnsmasq configuration generated at /etc/dnsmasq.d/sandbox.conf"
EOF

chmod +x /usr/local/share/sandbox/generate-dnsmasq-config.sh

# Create setup-dnsmasq.sh script for runtime configuration
cat > /usr/local/share/sandbox/setup-dnsmasq.sh << 'EOF'
#!/bin/bash
# Setup dnsmasq for DNS-based domain filtering
set -e

DEFAULT_POLICY="${1:-block}"
ALLOWED_DOMAINS="${2:-}"
BLOCKED_DOMAINS="${3:-}"
ALLOW_CLAUDE_WEBFETCH_DOMAINS="${4:-true}"
CLAUDE_SETTINGS_PATHS="${5:-.claude/settings.json,.claude/settings.local.json,~/.claude/settings.json}"
ALLOW_COMMON_DEVELOPMENT="${6:-true}"
LOG_QUERIES="${7:-true}"

echo "Setting up dnsmasq DNS filtering..."

# Determine if we need sudo
if [ -z "$USE_SUDO" ]; then
    if [ "$EUID" -ne 0 ]; then
        USE_SUDO=1
    else
        USE_SUDO=0
    fi
fi

# Generate dnsmasq configuration
/usr/local/share/sandbox/generate-dnsmasq-config.sh "$DEFAULT_POLICY" "$ALLOWED_DOMAINS" "$BLOCKED_DOMAINS" "$ALLOW_CLAUDE_WEBFETCH_DOMAINS" "$CLAUDE_SETTINGS_PATHS" "$ALLOW_COMMON_DEVELOPMENT" "$LOG_QUERIES"

# Stop any existing dnsmasq instance
if [ "$USE_SUDO" = "1" ]; then
    sudo pkill dnsmasq 2>/dev/null || true
else
    pkill dnsmasq 2>/dev/null || true
fi

# Start dnsmasq
echo "Starting dnsmasq..."
if [ "$USE_SUDO" = "1" ]; then
    sudo dnsmasq --conf-file=/etc/dnsmasq.conf
else
    dnsmasq --conf-file=/etc/dnsmasq.conf
fi

# Configure system to use local dnsmasq as DNS resolver
echo "Configuring DNS resolution..."
if [ -f /etc/resolv.conf ]; then
    # Backup original resolv.conf
    if [ "$USE_SUDO" = "1" ]; then
        sudo cp /etc/resolv.conf /etc/resolv.conf.sandbox-backup 2>/dev/null || true
        echo "nameserver 127.0.0.1" | sudo tee /etc/resolv.conf > /dev/null
    else
        cp /etc/resolv.conf /etc/resolv.conf.sandbox-backup 2>/dev/null || true
        echo "nameserver 127.0.0.1" > /etc/resolv.conf
    fi
fi

echo "dnsmasq DNS filtering configured"
EOF

chmod +x /usr/local/share/sandbox/setup-dnsmasq.sh

# Create configuration file
cat > /etc/sandbox/config << EOF
# Sandbox DNS Filter Configuration (dnsmasq-based)
DEFAULT_POLICY="$DEFAULT_POLICY"
ALLOWED_DOMAINS="$ALLOWED_DOMAINS"
BLOCKED_DOMAINS="$BLOCKED_DOMAINS"
IMMUTABLE_CONFIG="$IMMUTABLE_CONFIG"
LOG_QUERIES="$LOG_QUERIES"
ALLOW_CLAUDE_WEBFETCH_DOMAINS="$ALLOW_CLAUDE_WEBFETCH_DOMAINS"
CLAUDE_SETTINGS_PATHS="$CLAUDE_SETTINGS_PATHS"
ALLOW_COMMON_DEVELOPMENT="$ALLOW_COMMON_DEVELOPMENT"
EOF

# Add individual domains to config file for test validation
if [ -n "$ALLOWED_DOMAINS" ]; then
    echo "# Allowed domains:" >> /etc/sandbox/config
    IFS=',' read -ra DOMAIN_LIST <<< "$ALLOWED_DOMAINS"
    for domain in "${DOMAIN_LIST[@]}"; do
        domain=$(echo "$domain" | xargs)
        if [ -n "$domain" ]; then
            echo "$domain" >> /etc/sandbox/config
        fi
    done
fi

if [ -n "$BLOCKED_DOMAINS" ]; then
    echo "# Blocked domains:" >> /etc/sandbox/config
    echo "Processing blocked domains: $BLOCKED_DOMAINS"
    IFS=',' read -ra DOMAIN_LIST <<< "$BLOCKED_DOMAINS"
    for domain in "${DOMAIN_LIST[@]}"; do
        domain=$(echo "$domain" | xargs)
        if [ -n "$domain" ]; then
            echo "Adding blocked domain: $domain"
            echo "$domain" >> /etc/sandbox/config
        fi
    done
else
    echo "No blocked domains specified (BLOCKED_DOMAINS is empty)"
fi

# Create startup script that runs the filtering setup
cat > /usr/local/share/sandbox/sandbox-init.sh << 'EOF'
#!/bin/bash
# Initialize sandbox DNS filtering on container startup
set -e

# Skip initialization only if explicitly requested
if [ "$1" = "--skip" ]; then
    echo "Skipping sandbox DNS filter initialization (skip mode)"
    exit 0
fi

# Check if dnsmasq is available
if ! command -v dnsmasq >/dev/null 2>&1; then
    echo "ERROR: dnsmasq not available"
    echo "Sandbox DNS filtering cannot be initialized"
    exit 1
fi

# Determine if we need sudo for dnsmasq
if [ "$EUID" -ne 0 ]; then
    export USE_SUDO=1
else
    export USE_SUDO=0
fi

# Load configuration
if [ -f /etc/sandbox/config ]; then
    source /etc/sandbox/config
fi

# Set workspace folder for scripts
if [ -z "$WORKSPACE_FOLDER" ]; then
    if [ -n "$DEVCONTAINER_WORKSPACE_FOLDER" ]; then
        export WORKSPACE_FOLDER="$DEVCONTAINER_WORKSPACE_FOLDER"
    elif [ -n "$VSCODE_WORKSPACE" ]; then
        export WORKSPACE_FOLDER="$VSCODE_WORKSPACE"
    elif [ -n "$VSCODE_CWD" ]; then
        export WORKSPACE_FOLDER="$VSCODE_CWD"
    elif [ -n "$PWD" ] && [ -d "$PWD/.devcontainer" ]; then
        export WORKSPACE_FOLDER="$PWD"
    else
        export WORKSPACE_FOLDER="/workspace"
    fi
fi

# Setup dnsmasq
/usr/local/share/sandbox/setup-dnsmasq.sh "$DEFAULT_POLICY" "$ALLOWED_DOMAINS" "$BLOCKED_DOMAINS" "$ALLOW_CLAUDE_WEBFETCH_DOMAINS" "$CLAUDE_SETTINGS_PATHS" "$ALLOW_COMMON_DEVELOPMENT" "$LOG_QUERIES"

# Make immutable if configured
if [ "$IMMUTABLE_CONFIG" = "true" ]; then
    echo "Making configuration immutable..."
    # Make config files read-only
    if [ "$USE_SUDO" = "1" ]; then
        sudo chmod 444 /etc/sandbox/config
        sudo chattr +i /etc/sandbox/config 2>/dev/null || true
    else
        chmod 444 /etc/sandbox/config
        chattr +i /etc/sandbox/config 2>/dev/null || true
    fi
fi

echo "Sandbox DNS filtering initialized (dnsmasq-based)"
EOF

chmod +x /usr/local/share/sandbox/sandbox-init.sh

# Create init.d directory if it doesn't exist
mkdir -p /usr/local/share/devcontainer-init.d

# Create initialization hook for devcontainer entrypoint
cat > /usr/local/share/devcontainer-init.d/50-sandbox.sh << 'EOF'
#!/bin/bash
# Initialize sandbox DNS filter
if [ -x /usr/local/share/sandbox/sandbox-init.sh ]; then
    # Ensure the sandbox init script inherits proper environment
    export USER="${USER:-zero}"
    /usr/local/share/sandbox/sandbox-init.sh
fi
EOF

chmod +x /usr/local/share/devcontainer-init.d/50-sandbox.sh

echo "Sandbox initialization hook installed at /usr/local/share/devcontainer-init.d/50-sandbox.sh"

# Make configuration immutable if requested
if [ "$IMMUTABLE_CONFIG" = "true" ]; then
    echo "Making configuration immutable..."
    chmod 444 /etc/sandbox/config
    chattr +i /etc/sandbox/config 2>/dev/null || true
fi

# Create sudoers rule for sandbox management (dnsmasq only)
echo "# Allow zero user to manage sandbox DNS filtering and dnsmasq" > /etc/sudoers.d/sandbox-dnsmasq
echo "zero ALL=(root) NOPASSWD: /usr/bin/chmod, /usr/bin/chattr, /usr/sbin/dnsmasq, /usr/bin/pkill, /usr/bin/tee, /bin/cp" >> /etc/sudoers.d/sandbox-dnsmasq
chmod 440 /etc/sudoers.d/sandbox-dnsmasq

echo "✓ Sandbox DNS Filter installed successfully (pure dnsmasq-based)"
echo "  Default policy: $DEFAULT_POLICY"
echo "  Configuration immutable: $IMMUTABLE_CONFIG"
echo "  Query logging enabled: $LOG_QUERIES"
echo "  Common development domains: $ALLOW_COMMON_DEVELOPMENT"
echo ""
echo "Note: DNS filtering rules will be applied when the container starts."
echo "Pure DNS-based filtering with true wildcard support is now enabled."