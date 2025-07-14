#!/bin/bash
# Unified entrypoint for devcontainer variants
# Handles sandbox initialization, docker socket forwarding, and VS Code integration

set -e

# Define the state file location (only writable by root)
SANDBOX_STATE_FILE="/var/lib/devcontainer-sandbox/enabled"
SANDBOX_STATE_DIR=$(dirname "$SANDBOX_STATE_FILE")

# Docker socket configuration
SOCAT_PATH_BASE=/tmp/vscr-docker-from-docker
SOCAT_LOG=${SOCAT_PATH_BASE}.log
SOCAT_PID=${SOCAT_PATH_BASE}.pid
USERNAME="${USERNAME:-zero}"
SOURCE_SOCKET="${SOURCE_SOCKET:-/var/run/docker-host.sock}"
TARGET_SOCKET="${TARGET_SOCKET:-/var/run/docker.sock}"

# Wrapper function to only use sudo if not already root
sudoIf() {
    if [ "$(id -u)" -ne 0 ]; then
        sudo "$@"
    else
        "$@"
    fi
}

# Log messages for docker
log() {
    echo -e "[$(date)] $@" | sudoIf tee -a ${SOCAT_LOG} > /dev/null
}

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

# Check if running in DIND variant
is_dind_variant() {
    [ -f "/usr/local/share/docker-init.sh" ] || [ -S "${SOURCE_SOCKET}" ]
}

# Initialize Docker socket forwarding for DIND variant
init_docker_socket() {
    echo -e "\n** $(date) **" | sudoIf tee -a ${SOCAT_LOG} > /dev/null
    log "Ensuring ${USERNAME} has access to ${SOURCE_SOCKET} via ${TARGET_SOCKET}"

    # If enabled, try to update the docker group with the right GID. If the group is root,
    # fall back on using socat to forward the docker socket to another unix socket so
    # that we can set permissions on it without affecting the host.
    if [ "${SOURCE_SOCKET}" != "${TARGET_SOCKET}" ] && [ "${USERNAME}" != "root" ] && [ "${USERNAME}" != "0" ]; then
        DOCKER_GID="$(grep -oP '^docker:x:\K[^:]+' /etc/group || echo '')"
        SOCKET_GID=$(stat -c '%g' ${SOURCE_SOCKET})
        
        if [ "${SOCKET_GID}" != "0" ] && [ "${SOCKET_GID}" != "${DOCKER_GID}" ] && ! grep -E ".+:x:${SOCKET_GID}" /etc/group; then
            sudoIf groupmod --gid "${SOCKET_GID}" docker
        else
            # Enable proxy if not already running
            if [ ! -f "${SOCAT_PID}" ] || ! ps -p $(cat ${SOCAT_PID}) > /dev/null; then
                log "Enabling socket proxy."
                log "Proxying ${SOURCE_SOCKET} to ${TARGET_SOCKET} for vscode"
                sudoIf rm -rf ${TARGET_SOCKET}
                (sudoIf socat UNIX-LISTEN:${TARGET_SOCKET},fork,mode=660,user=${USERNAME},backlog=128 UNIX-CONNECT:${SOURCE_SOCKET} 2>&1 | sudoIf tee -a ${SOCAT_LOG} > /dev/null & echo "$!" | sudoIf tee ${SOCAT_PID} > /dev/null)
            else
                log "Socket proxy already running."
            fi
        fi
        log "Success"
    fi
}

# Main initialization
echo "🚀 Initializing devcontainer..."

# Handle DIND variant
if is_dind_variant; then
    echo "🐳 Docker-in-Docker variant detected"
    init_docker_socket
fi

# Initialize sandbox state
initialize_sandbox_state

# Check the immutable state file
SANDBOX_ENABLED=$(read_sandbox_state)

if [ "$SANDBOX_ENABLED" = "true" ]; then
    echo "🔒 Sandbox mode is enabled (immutable)"
    
    # Check if we're in a devcontainer environment
    if [ -n "${DEVCONTAINER}" ] || [ -n "${CODESPACES}" ] || [ -n "${REMOTE_CONTAINERS}" ]; then
        # Read firewall config from immutable state
        FIREWALL_ENABLED=$(cat "${SANDBOX_STATE_DIR}/firewall" 2>/dev/null || echo "false")
        
        if [ "$FIREWALL_ENABLED" = "true" ]; then
            # Check if firewall is already initialized
            if ! sudo iptables -L OUTPUT -n | grep -q "policy DROP" 2>/dev/null; then
                echo "🔥 Initializing sandbox firewall..."
                
                # Read allowed domains from immutable state
                ALLOWED_DOMAINS=$(cat "${SANDBOX_STATE_DIR}/domains" 2>/dev/null || echo "")
                if [ -n "$ALLOWED_DOMAINS" ]; then
                    export ADDITIONAL_ALLOWED_DOMAINS="$ALLOWED_DOMAINS"
                fi
                
                # Run firewall initialization
                if sudo /usr/local/share/sandbox/init-firewall.sh; then
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

# Signal VS Code that initialization is complete
if [ -n "${VSCODE_IPC_HOOK_CLI}" ] || [ -n "${REMOTE_CONTAINERS}" ]; then
    echo "📋 Devcontainer initialization complete"
    # Add a marker file that VS Code can detect
    touch /tmp/.devcontainer-init-complete
    
    # If this is the initial VS Code terminal, signal to close it
    if [ -n "${VSCODE_DEVCONTAINER_INIT}" ]; then
        echo "🔄 Closing initialization terminal..."
        # Give VS Code time to read the output
        sleep 2
        exit 0
    fi
fi

# Execute the command or start interactive shell
if [ $# -eq 0 ] && [ -t 0 ]; then
    # No arguments and running interactively, start zsh
    exec zsh -l
else
    # Execute whatever command was passed
    exec "$@"
fi