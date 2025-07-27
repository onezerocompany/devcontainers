#!/bin/bash
# Sandbox Network Filter Feature Installation Script
set -e

echo "Starting Sandbox Network Filter installation..."

# Detect if we're in a Docker build context
# Only check for explicit build environment variables
if [ -n "$DOCKER_BUILDKIT" ] || [ -n "$BUILDKIT_PROGRESS" ] || [ -n "$BUILDX_BUILDER" ]; then
    echo "Detected Docker build environment - will skip DNS resolution"
    export IN_DOCKER_BUILD=true
else
    export IN_DOCKER_BUILD=false
fi

# Ensure non-interactive mode for apt
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

# Feature options
DEFAULT_POLICY="${DEFAULTPOLICY:-block}"
ALLOWED_DOMAINS="${ALLOWEDDOMAINS:-}"
BLOCKED_DOMAINS="${BLOCKEDDOMAINS:-}"
ALLOW_DOCKER_NETWORKS="${ALLOWDOCKERNETWORKS:-true}"
ALLOW_LOCALHOST="${ALLOWLOCALHOST:-true}"
IMMUTABLE_CONFIG="${IMMUTABLECONFIG:-true}"
LOG_BLOCKED="${LOGBLOCKED:-true}"
ALLOW_CLAUDE_WEBFETCH_DOMAINS="${ALLOWCLAUDEWEBFETCHDOMAINS:-true}"
CLAUDE_SETTINGS_PATHS="${CLAUDESETTINGSPATHS:-.claude/settings.json,.claude/settings.local.json,~/.claude/settings.json}"

echo "Installing Sandbox Network Filter..."

# Install required packages
echo "Installing required packages..."

# Pre-create iptables rules directory to avoid interactive prompts
mkdir -p /etc/iptables
# Create empty rules files to prevent iptables-persistent from prompting
echo -e "*filter\n:INPUT ACCEPT [0:0]\n:FORWARD ACCEPT [0:0]\n:OUTPUT ACCEPT [0:0]\nCOMMIT" > /etc/iptables/rules.v4
echo -e "*filter\n:INPUT ACCEPT [0:0]\n:FORWARD ACCEPT [0:0]\n:OUTPUT ACCEPT [0:0]\nCOMMIT" > /etc/iptables/rules.v6

# Pre-configure iptables-persistent to avoid prompts
echo iptables-persistent iptables-persistent/autosave_v4 boolean false | debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean false | debconf-set-selections

echo "Running apt-get update..."
apt-get update -qq
echo "Installing packages..."
apt-get install -y -qq --no-install-recommends iptables iptables-persistent netfilter-persistent jq dnsutils
echo "Package installation complete"

# Create sandbox directories
mkdir -p /usr/local/share/sandbox
mkdir -p /etc/sandbox

# Create iptables rule management script 
cat > /usr/local/share/sandbox/setup-rules.sh << 'EOF'
#!/bin/bash
# Setup iptables rules for sandbox network filtering
set -e

ALLOW_DOCKER_NETWORKS="${1:-true}"
ALLOW_LOCALHOST="${2:-true}"
DEFAULT_POLICY="${3:-block}"
LOG_BLOCKED="${4:-true}"
ALLOW_CLAUDE_WEBFETCH_DOMAINS="${5:-true}"
CLAUDE_SETTINGS_PATHS="${6:-.claude/settings.json,.claude/settings.local.json,~/.claude/settings.json}"
ALLOWED_DOMAINS="${7:-}"
BLOCKED_DOMAINS="${8:-}"

# Detect if we're in a Docker build context
# Only check for explicit build environment variables
if [ -n "$DOCKER_BUILDKIT" ] || [ -n "$BUILDKIT_PROGRESS" ] || [ -n "$BUILDX_BUILDER" ]; then
    IN_DOCKER_BUILD=true
else
    # Additional check: if iptables doesn't work properly, we're likely in a build
    if ! command -v iptables >/dev/null 2>&1 || ! iptables -L OUTPUT >/dev/null 2>&1; then
        IN_DOCKER_BUILD=true
    else
        IN_DOCKER_BUILD=false
    fi
fi

echo "Setting up network filtering rules..."

# Skip all iptables operations during Docker build
if [ "$IN_DOCKER_BUILD" = "true" ]; then
    echo "Detected Docker build environment - skipping iptables configuration"
    echo "Network filtering will be configured when the container starts"
    exit 0
fi

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

# Allow Claude WebFetch domains if enabled
if [ "$ALLOW_CLAUDE_WEBFETCH_DOMAINS" = "true" ]; then
    # Skip DNS resolution during Docker build
    if [ "$IN_DOCKER_BUILD" = "true" ]; then
        echo "Skipping Claude WebFetch domain resolution during Docker build"
    else
        echo "Extracting and allowing Claude WebFetch domains..."
        
        # Set workspace folder environment variables for the extraction script
        # Check multiple possible workspace environment variables
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
        
        # Extract domains and get IPs with timeout
        claude_ips=$(timeout 30 /usr/local/share/sandbox/extract-claude-domains.sh "$CLAUDE_SETTINGS_PATHS" | tail -n +2 | grep -E '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$' || true)
        
        if [ -n "$claude_ips" ]; then
            echo "Adding rules for Claude WebFetch IPs:"
            while IFS= read -r ip; do
                if [ -n "$ip" ]; then
                    echo "  Allowing: $ip"
                    iptables -t filter -A SANDBOX_OUTPUT -d "$ip" -j ACCEPT
                fi
            done <<< "$claude_ips"
        else
            echo "No Claude WebFetch domains found or could not resolve"
        fi
    fi
fi

# Common subdomains for developers
COMMON_SUBDOMAINS=(
    "api" "docs" "dev" "app" "www" "cdn" "static" "assets" "images" 
    "support" "help" "dashboard" "console" "admin" "portal" "auth"
    "login" "secure" "staging" "test" "demo" "sandbox" "beta"
    "v1" "v2" "v3" "api-v1" "api-v2" "graphql" "rest" "ws"
    "files" "download" "uploads" "media" "content" "data"
    "github" "gitlab" "git" "repo" "registry" "packages"
    "metrics" "logs" "monitor" "status" "health"
    "mail" "smtp" "email" "notifications"
    "chat" "messaging" "realtime" "stream"
    "search" "elasticsearch" "solr"
    "db" "database" "mysql" "postgres" "mongo" "redis"
)

# Handle custom allowed domains
if [ -n "$ALLOWED_DOMAINS" ]; then
    # Skip DNS resolution during Docker build
    if [ "$IN_DOCKER_BUILD" = "true" ]; then
        echo "Skipping allowed domains resolution during Docker build: $ALLOWED_DOMAINS"
    else
        echo "Processing allowed domains: $ALLOWED_DOMAINS"
        IFS=',' read -ra DOMAIN_LIST <<< "$ALLOWED_DOMAINS"
        for domain in "${DOMAIN_LIST[@]}"; do
            # Trim whitespace
            domain=$(echo "$domain" | xargs)
            original_domain="$domain"
            
            # Check if it's a wildcard domain
            if [[ "$domain" == \*.* ]]; then
                # Remove wildcard prefix
                base_domain=${domain#\*.}
                echo "  Scanning common subdomains for wildcard domain: $original_domain"
                
                # Try common subdomains
                for subdomain in "${COMMON_SUBDOMAINS[@]}"; do
                    full_domain="$subdomain.$base_domain"
                    # Resolve domain to IPs with timeout
                    resolved_ips=$(timeout 2 dig +short +time=1 +tries=1 "$full_domain" A 2>/dev/null | grep -E '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$' || true)
                    
                    if [ -n "$resolved_ips" ]; then
                        while IFS= read -r ip; do
                            if [ -n "$ip" ]; then
                                echo "    Allowing IP: $ip for subdomain $full_domain"
                                iptables -t filter -A SANDBOX_OUTPUT -d "$ip" -j ACCEPT
                            fi
                        done <<< "$resolved_ips"
                    fi
                done
            else
                # Non-wildcard domain
                echo "  Resolving allowed domain: $domain"
                # Resolve domain to IPs with timeout
                resolved_ips=$(timeout 5 dig +short +time=2 +tries=1 "$domain" A 2>/dev/null | grep -E '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$' || true)
                
                if [ -n "$resolved_ips" ]; then
                    while IFS= read -r ip; do
                        if [ -n "$ip" ]; then
                            echo "    Allowing IP: $ip for domain $domain"
                            iptables -t filter -A SANDBOX_OUTPUT -d "$ip" -j ACCEPT
                        fi
                    done <<< "$resolved_ips"
                else
                    echo "    Could not resolve domain: $domain"
                fi
            fi
        done
    fi
fi

# Handle custom blocked domains
if [ -n "$BLOCKED_DOMAINS" ]; then
    # Skip DNS resolution during Docker build
    if [ "$IN_DOCKER_BUILD" = "true" ]; then
        echo "Skipping blocked domains resolution during Docker build: $BLOCKED_DOMAINS"
    else
        echo "Processing blocked domains: $BLOCKED_DOMAINS"
        IFS=',' read -ra DOMAIN_LIST <<< "$BLOCKED_DOMAINS"
        for domain in "${DOMAIN_LIST[@]}"; do
            # Trim whitespace
            domain=$(echo "$domain" | xargs)
            original_domain="$domain"
            
            # Check if it's a wildcard domain
            if [[ "$domain" == \*.* ]]; then
                # Remove wildcard prefix
                base_domain=${domain#\*.}
                echo "  Scanning common subdomains for wildcard domain: $original_domain"
                
                # Try common subdomains
                for subdomain in "${COMMON_SUBDOMAINS[@]}"; do
                    full_domain="$subdomain.$base_domain"
                    # Resolve domain to IPs with timeout
                    resolved_ips=$(timeout 2 dig +short +time=1 +tries=1 "$full_domain" A 2>/dev/null | grep -E '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$' || true)
                    
                    if [ -n "$resolved_ips" ]; then
                        while IFS= read -r ip; do
                            if [ -n "$ip" ]; then
                                echo "    Blocking IP: $ip for subdomain $full_domain"
                                if [ "$LOG_BLOCKED" = "true" ]; then
                                    iptables -t filter -A SANDBOX_OUTPUT -d "$ip" -j LOG --log-prefix "SANDBOX_BLOCKED_DOMAIN: " --log-level 4
                                fi
                                iptables -t filter -A SANDBOX_OUTPUT -d "$ip" -j REJECT --reject-with icmp-host-unreachable
                            fi
                        done <<< "$resolved_ips"
                    fi
                done
            else
                # Non-wildcard domain
                echo "  Resolving blocked domain: $domain"
                # Resolve domain to IPs with timeout
                resolved_ips=$(timeout 5 dig +short +time=2 +tries=1 "$domain" A 2>/dev/null | grep -E '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$' || true)
                
                if [ -n "$resolved_ips" ]; then
                    while IFS= read -r ip; do
                        if [ -n "$ip" ]; then
                            echo "    Blocking IP: $ip for domain $domain"
                            if [ "$LOG_BLOCKED" = "true" ]; then
                                iptables -t filter -A SANDBOX_OUTPUT -d "$ip" -j LOG --log-prefix "SANDBOX_BLOCKED_DOMAIN: " --log-level 4
                            fi
                            iptables -t filter -A SANDBOX_OUTPUT -d "$ip" -j REJECT --reject-with icmp-host-unreachable
                        fi
                    done <<< "$resolved_ips"
                else
                    echo "    Could not resolve domain: $domain"
                fi
            fi
        done
    fi
fi

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

echo "Network filtering rules configured"
EOF

chmod +x /usr/local/share/sandbox/setup-rules.sh

# Create Claude domain extraction script
cat > /usr/local/share/sandbox/extract-claude-domains.sh << 'EOF'
#!/bin/bash
# Extract WebFetch domains from Claude settings files and resolve to IPs
set -e

CLAUDE_SETTINGS_PATHS="$1"

echo "Extracting Claude WebFetch domains..."

# Detect workspace folder from various environment variables
if [ -n "$WORKSPACE_FOLDER" ]; then
    workspace_dir="$WORKSPACE_FOLDER"
elif [ -n "$DEVCONTAINER_WORKSPACE_FOLDER" ]; then
    workspace_dir="$DEVCONTAINER_WORKSPACE_FOLDER"
elif [ -n "$VSCODE_WORKSPACE" ]; then
    workspace_dir="$VSCODE_WORKSPACE"
elif [ -n "$VSCODE_CWD" ]; then
    workspace_dir="$VSCODE_CWD"
elif [ -n "$PWD" ] && [ -d "$PWD/.devcontainer" ]; then
    # If we're in a directory with .devcontainer, assume it's the workspace
    workspace_dir="$PWD"
else
    # Default fallback
    workspace_dir="/workspace"
fi

echo "  Detected workspace folder: $workspace_dir"

# Array to store unique domains
declare -a domains=()
# Array to store original domains (with wildcards)
declare -a original_domains=()

# Function to extract domains from a settings file
extract_domains_from_file() {
    local file="$1"
    
    if [ ! -f "$file" ]; then
        echo "  Not found: $file"
        return
    fi
    
    echo "  Reading: $file"
    
    # Extract WebFetch rules from permissions.allow array
    local webfetch_rules=$(jq -r '.permissions.allow[]? | select(startswith("WebFetch(domain:"))' "$file" 2>/dev/null || true)
    
    while IFS= read -r rule; do
        if [ -n "$rule" ]; then
            # Extract domain from WebFetch(domain:example.com) format
            local domain=$(echo "$rule" | sed -n 's/WebFetch(domain:\([^)]*\))/\1/p')
            if [ -n "$domain" ]; then
                # Store original domain (with wildcard if present)
                original_domains+=("$domain")
                # Remove wildcard prefix if present
                domain=${domain#\*.}
                domains+=("$domain")
                echo "    Found domain: $domain"
            fi
        fi
    done <<< "$webfetch_rules"
}

# Process each settings file path
IFS=',' read -ra PATHS <<< "$CLAUDE_SETTINGS_PATHS"
for path in "${PATHS[@]}"; do
    # Trim whitespace
    path=$(echo "$path" | xargs)
    
    # Expand tilde to home directory
    expanded_path="${path/#\~/$HOME}"
    
    # If path doesn't start with /, assume it's relative to workspace
    if [[ "$expanded_path" != /* ]]; then
        expanded_path="$workspace_dir/$expanded_path"
    fi
    
    extract_domains_from_file "$expanded_path"
done

# Remove duplicates
domains=($(printf "%s\n" "${domains[@]}" | sort -u))
original_domains=($(printf "%s\n" "${original_domains[@]}" | sort -u))

echo "\nResolving domains to IP addresses..."

# Array to store unique IPs
declare -a ips=()

# Common subdomains for developers
COMMON_SUBDOMAINS=(
    "api" "docs" "dev" "app" "www" "cdn" "static" "assets" "images" 
    "support" "help" "dashboard" "console" "admin" "portal" "auth"
    "login" "secure" "staging" "test" "demo" "sandbox" "beta"
    "v1" "v2" "v3" "api-v1" "api-v2" "graphql" "rest" "ws"
    "files" "download" "uploads" "media" "content" "data"
    "github" "gitlab" "git" "repo" "registry" "packages"
    "metrics" "logs" "monitor" "status" "health"
    "mail" "smtp" "email" "notifications"
    "chat" "messaging" "realtime" "stream"
    "search" "elasticsearch" "solr"
    "db" "database" "mysql" "postgres" "mongo" "redis"
)

# Resolve each domain to IPs
for domain in "${domains[@]}"; do
    # Check if this was originally a wildcard domain
    is_wildcard=false
    for original_domain in "${original_domains[@]}"; do
        if [[ "$original_domain" == "*.$domain" ]]; then
            is_wildcard=true
            break
        fi
    done
    
    if [ "$is_wildcard" = true ]; then
        echo "  Scanning common subdomains for wildcard domain: *.$domain"
        subdomain_count=0
        
        # Try common subdomains for wildcard domains
        for subdomain in "${COMMON_SUBDOMAINS[@]}"; do
            full_domain="$subdomain.$domain"
            echo -n "    Trying $full_domain... "
            
            # Try to resolve using dig with timeout
            if command -v dig >/dev/null 2>&1; then
                resolved_ips=$(timeout 2 dig +short +time=1 +tries=1 "$full_domain" A 2>/dev/null | grep -E '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$' || true)
            elif command -v nslookup >/dev/null 2>&1; then
                # Fallback to nslookup
                resolved_ips=$(timeout 2 nslookup "$full_domain" 2>/dev/null | grep -A 1 "Name:" | grep "Address:" | awk '{print $2}' | grep -E '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$' || true)
            else
                resolved_ips=""
            fi
            
            if [ -n "$resolved_ips" ]; then
                echo "FOUND"
                while IFS= read -r ip; do
                    if [ -n "$ip" ]; then
                        ips+=("$ip")
                        echo "      -> $ip"
                    fi
                done <<< "$resolved_ips"
                subdomain_count=$((subdomain_count + 1))
            else
                echo "not found"
            fi
        done
        
        echo "    Found $subdomain_count subdomains for *.$domain"
    else
        # Non-wildcard domain, resolve normally
        echo -n "  Resolving $domain... "
        
        # Try to resolve using dig (more reliable) with timeout
        if command -v dig >/dev/null 2>&1; then
            resolved_ips=$(timeout 5 dig +short +time=2 +tries=1 "$domain" A 2>/dev/null | grep -E '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$' || true)
        elif command -v nslookup >/dev/null 2>&1; then
            # Fallback to nslookup
            resolved_ips=$(nslookup "$domain" 2>/dev/null | grep -A 1 "Name:" | grep "Address:" | awk '{print $2}' | grep -E '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$' || true)
        else
            resolved_ips=""
        fi
        
        if [ -n "$resolved_ips" ]; then
            echo "OK"
            while IFS= read -r ip; do
                if [ -n "$ip" ]; then
                    ips+=("$ip")
                    echo "    -> $ip"
                fi
            done <<< "$resolved_ips"
        else
            echo "FAILED (could not resolve)"
        fi
    fi
done

# Remove duplicate IPs
ips=($(printf "%s\n" "${ips[@]}" | sort -u))

# Output unique IPs one per line
echo "\nResolved ${#ips[@]} unique IP addresses from Claude settings"
printf "%s\n" "${ips[@]}"
EOF

chmod +x /usr/local/share/sandbox/extract-claude-domains.sh

# Create configuration file
cat > /etc/sandbox/config << EOF
# Sandbox Network Filter Configuration
DEFAULT_POLICY="$DEFAULT_POLICY"
ALLOWED_DOMAINS="$ALLOWED_DOMAINS"
BLOCKED_DOMAINS="$BLOCKED_DOMAINS"
ALLOW_DOCKER_NETWORKS="$ALLOW_DOCKER_NETWORKS"
ALLOW_LOCALHOST="$ALLOW_LOCALHOST"
IMMUTABLE_CONFIG="$IMMUTABLE_CONFIG"
LOG_BLOCKED="$LOG_BLOCKED"
ALLOW_CLAUDE_WEBFETCH_DOMAINS="$ALLOW_CLAUDE_WEBFETCH_DOMAINS"
CLAUDE_SETTINGS_PATHS="$CLAUDE_SETTINGS_PATHS"
EOF

# Add individual domains to config file for test validation
if [ -n "$ALLOWED_DOMAINS" ]; then
    echo "# Allowed domains:" >> /etc/sandbox/config
    IFS=',' read -ra DOMAIN_LIST <<< "$ALLOWED_DOMAINS"
    for domain in "${DOMAIN_LIST[@]}"; do
        domain=$(echo "$domain" | xargs)
        # Keep the original domain format (including wildcards) in config
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
        # Keep the original domain format (including wildcards) in config
        if [ -n "$domain" ]; then
            echo "Adding blocked domain: $domain"
            echo "$domain" >> /etc/sandbox/config
        fi
    done
else
    echo "No blocked domains specified (BLOCKED_DOMAINS is empty)"
fi

# Skip iptables setup during Docker build - will be configured at runtime
if [ "$IN_DOCKER_BUILD" = "true" ]; then
    echo "Skipping iptables configuration during build (will be applied at container startup)"
else
    echo "Note: iptables configuration will be applied at container startup"
fi

# Create startup script that runs the filtering setup
cat > /usr/local/share/sandbox/sandbox-init.sh << 'EOF'
#!/bin/bash
# Initialize sandbox network filtering on container startup
set -e

# Skip initialization only if we're explicitly in build mode or skip is requested
if [ -n "$DOCKER_BUILDKIT" ] || [ -n "$BUILDKIT_PROGRESS" ] || [ "$1" = "--skip" ]; then
    echo "Skipping sandbox network filter initialization (build or skip mode)"
    exit 0
fi

# Additional runtime check - if iptables is not available or doesn't work, skip
if ! command -v iptables >/dev/null 2>&1 || ! iptables -L OUTPUT >/dev/null 2>&1; then
    echo "Skipping sandbox network filter initialization (iptables not available or not working)"
    exit 0
fi


# Load configuration
if [ -f /etc/sandbox/config ]; then
    source /etc/sandbox/config
fi

# Set workspace folder for scripts - check multiple environment variables
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

# Setup iptables rules
/usr/local/share/sandbox/setup-rules.sh "$ALLOW_DOCKER_NETWORKS" "$ALLOW_LOCALHOST" "$DEFAULT_POLICY" "$LOG_BLOCKED" "$ALLOW_CLAUDE_WEBFETCH_DOMAINS" "$CLAUDE_SETTINGS_PATHS" "$ALLOWED_DOMAINS" "$BLOCKED_DOMAINS"

# Make immutable if configured
if [ "$IMMUTABLE_CONFIG" = "true" ]; then
    echo "Making configuration immutable..."
    # Save current rules
    iptables-save > /etc/iptables/rules.v4
    # Make config files read-only
    chmod 444 /etc/sandbox/config
    chattr +i /etc/sandbox/config 2>/dev/null || true
fi

echo "Sandbox network filtering initialized"
EOF

chmod +x /usr/local/share/sandbox/sandbox-init.sh

# Skip saving iptables rules during build (will be saved at runtime)
echo "Skipping iptables rules save during build"

# Create init.d directory if it doesn't exist
mkdir -p /usr/local/share/devcontainer-init.d

# Create initialization hook for devcontainer entrypoint
cat > /usr/local/share/devcontainer-init.d/50-sandbox.sh << 'EOF'
#!/bin/bash
# Initialize sandbox network filter
if [ -x /usr/local/share/sandbox/sandbox-init.sh ]; then
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

echo "✓ Sandbox Network Filter installed successfully"
echo "  Default policy: $DEFAULT_POLICY"
echo "  Docker networks allowed: $ALLOW_DOCKER_NETWORKS"
echo "  Localhost allowed: $ALLOW_LOCALHOST"
echo "  Configuration immutable: $IMMUTABLE_CONFIG"
echo "  Logging enabled: $LOG_BLOCKED"
echo ""
echo "Note: Network filtering rules will be applied when the container starts."