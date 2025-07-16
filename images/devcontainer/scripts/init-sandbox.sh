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
        if [ "${DEVCONTAINER_SANDBOX_ENABLED}" = "true" ]; then
            echo "true" | sudoIf tee "$SANDBOX_STATE_FILE" > /dev/null
            sudoIf chmod 444 "$SANDBOX_STATE_FILE"  # Read-only for everyone, owned by root
            
            # Also save firewall and domains config
            echo "${DEVCONTAINER_SANDBOX_FIREWALL:-false}" | sudoIf tee "${SANDBOX_STATE_DIR}/firewall" > /dev/null
            echo "${DEVCONTAINER_SANDBOX_ALLOWED_DOMAINS:-}" | sudoIf tee "${SANDBOX_STATE_DIR}/domains" > /dev/null
            sudoIf chmod 444 "${SANDBOX_STATE_DIR}/firewall" "${SANDBOX_STATE_DIR}/domains"
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
    echo "🔒 Sandbox mode is enabled (immutable)"
    
    # Check if we're in a devcontainer environment or if explicitly enabled
    if [ -n "${DEVCONTAINER}" ] || [ -n "${CODESPACES}" ] || [ -n "${REMOTE_CONTAINERS}" ] || [ "${ENABLE_SANDBOX_FIREWALL}" = "true" ]; then
        # Read firewall config from immutable state
        FIREWALL_ENABLED=$(cat "${SANDBOX_STATE_DIR}/firewall" 2>/dev/null || echo "false")
        
        if [ "$FIREWALL_ENABLED" = "true" ]; then
            # Check if firewall is already initialized
            if ! sudoIf iptables -L OUTPUT -n | grep -q "policy DROP" 2>/dev/null; then
                echo "🔥 Initializing sandbox firewall..."
                
                # Read allowed domains from immutable state
                ALLOWED_DOMAINS=$(cat "${SANDBOX_STATE_DIR}/domains" 2>/dev/null || echo "")
                if [ -n "$ALLOWED_DOMAINS" ]; then
                    export ADDITIONAL_ALLOWED_DOMAINS="$ALLOWED_DOMAINS"
                fi
                
                # Run firewall initialization
                if sudoIf /usr/local/share/sandbox/init-firewall.sh; then
                    echo "✅ Firewall initialized successfully"
                else
                    echo "⚠️  Warning: Firewall initialization failed"
                fi
            else
                echo "✅ Firewall already initialized"
            fi
        fi
    fi
else
    echo "🔓 Sandbox mode is disabled"
fi