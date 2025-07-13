#!/bin/bash
# Secure entrypoint wrapper that prevents sandbox tampering from inside the container

set -e

# Define the state file location (only writable by root)
SANDBOX_STATE_FILE="/var/lib/devcontainer-sandbox/enabled"
SANDBOX_STATE_DIR=$(dirname "$SANDBOX_STATE_FILE")

# Function to initialize sandbox state on first run
initialize_sandbox_state() {
    # Only root can create this directory and file
    if [ ! -d "$SANDBOX_STATE_DIR" ]; then
        sudo mkdir -p "$SANDBOX_STATE_DIR"
        sudo chmod 755 "$SANDBOX_STATE_DIR"  # Allow everyone to read the directory
    fi
    
    # Write the initial state based on environment variable
    # This happens only once when the container starts
    if [ ! -f "$SANDBOX_STATE_FILE" ]; then
        if [ "${DEVCONTAINER_SANDBOX_ENABLED}" = "true" ]; then
            echo "true" | sudo tee "$SANDBOX_STATE_FILE" > /dev/null
            sudo chmod 444 "$SANDBOX_STATE_FILE"  # Read-only for everyone, owned by root
            
            # Also save firewall and domains config
            echo "${DEVCONTAINER_SANDBOX_FIREWALL:-false}" | sudo tee "${SANDBOX_STATE_DIR}/firewall" > /dev/null
            echo "${DEVCONTAINER_SANDBOX_ALLOWED_DOMAINS:-}" | sudo tee "${SANDBOX_STATE_DIR}/domains" > /dev/null
            sudo chmod 444 "${SANDBOX_STATE_DIR}/firewall" "${SANDBOX_STATE_DIR}/domains"
        else
            echo "false" | sudo tee "$SANDBOX_STATE_FILE" > /dev/null
            sudo chmod 444 "$SANDBOX_STATE_FILE"
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

# Initialize state on first run
initialize_sandbox_state

# Check the immutable state file instead of environment variable
SANDBOX_ENABLED=$(read_sandbox_state)

if [ "$SANDBOX_ENABLED" = "true" ]; then
    # Only show messages if not in an interactive shell or if explicitly requested
    if [ -t 0 ] && [ -z "$DEVCONTAINER_QUIET" ]; then
        echo "Sandbox mode is enabled (immutable)" >&2
    fi
    
    # Check if we're in a devcontainer environment
    if [ -n "${DEVCONTAINER}" ] || [ -n "${CODESPACES}" ] || [ -n "${REMOTE_CONTAINERS}" ]; then
        # Read firewall config from immutable state
        FIREWALL_ENABLED=$(cat "${SANDBOX_STATE_DIR}/firewall" 2>/dev/null || echo "false")
        
        if [ "$FIREWALL_ENABLED" = "true" ]; then
            # Check if firewall is already initialized
            if ! sudo iptables -L OUTPUT -n | grep -q "policy DROP" 2>/dev/null; then
                # Only show messages if not in an interactive shell
                if [ -t 0 ] && [ -z "$DEVCONTAINER_QUIET" ]; then
                    echo "Initializing sandbox firewall..." >&2
                fi
                
                # Read allowed domains from immutable state
                ALLOWED_DOMAINS=$(cat "${SANDBOX_STATE_DIR}/domains" 2>/dev/null || echo "")
                if [ -n "$ALLOWED_DOMAINS" ]; then
                    export ADDITIONAL_ALLOWED_DOMAINS="$ALLOWED_DOMAINS"
                fi
                
                # Run firewall initialization
                sudo /usr/local/share/sandbox/init-firewall.sh || echo "Warning: Firewall initialization failed"
            else
                if [ -t 0 ] && [ -z "$DEVCONTAINER_QUIET" ]; then
                    echo "Firewall already initialized" >&2
                fi
            fi
        fi
    fi
else
    # Only show messages if not in an interactive shell
    if [ -t 0 ] && [ -z "$DEVCONTAINER_QUIET" ]; then
        echo "Sandbox mode is disabled" >&2
    fi
fi

# Execute the original command
exec "$@"