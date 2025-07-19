#!/bin/bash
# Unified entrypoint for base image containers
# Handles both standard and Docker-in-Docker variants

set -e

# Define required functions directly

# Run command as sudo only if not already root
sudoIf() {
    if [ "$(id -u)" -ne 0 ]; then
        sudo "$@"
    else
        "$@"
    fi
}

# Enhanced Docker-in-Docker detection
detect_dind() {
    # Check 1: Docker daemon binary exists
    if command -v dockerd >/dev/null 2>&1; then
        # Check 2: s6-overlay service for Docker exists
        if [ -d "/etc/s6-overlay/s6-rc.d/dockerd" ] || [ -f "/etc/s6-overlay/s6-rc.d/dockerd/type" ]; then
            return 0
        fi
        # Check 3: Running in container with Docker capabilities
        if [ -f "/.dockerenv" ]; then
            return 0
        fi
    fi
    
    return 1
}

# Common entrypoint execution logic
execute_command() {
    echo "[EXECUTE_COMMAND] Args: $@" >> /tmp/entrypoint.log
    echo "[EXECUTE_COMMAND] Interactive terminal: $([ -t 0 ] && echo 'yes' || echo 'no')" >> /tmp/entrypoint.log
    
    if [ $# -eq 0 ]; then
        # No command provided
        if [ -t 0 ]; then
            # Interactive terminal - start user's default shell
            # Get the user's default shell from /etc/passwd
            USER_SHELL=$(getent passwd $(whoami) | cut -d: -f7)
            echo "[EXECUTE_COMMAND] User shell from passwd: $USER_SHELL" >> /tmp/entrypoint.log
            # Fail if shell lookup fails
            if [ -z "$USER_SHELL" ]; then
                echo "Error: Could not determine user shell" >&2
                exit 1
            fi
            echo "[EXECUTE_COMMAND] Final shell choice: $USER_SHELL" >> /tmp/entrypoint.log
            exec $USER_SHELL -l
        else
            # Non-interactive - keep container running
            exec tail -f /dev/null
        fi
    else
        # Execute provided command
        echo "[EXECUTE_COMMAND] Executing command: $@" >> /tmp/entrypoint.log
        exec "$@"
    fi
}

USERNAME="${USERNAME:-zero}"

# Main initialization
echo "🚀 Initializing container..."
echo

# s6-overlay will manage services automatically
echo "  🔧 System services managed by s6-overlay"

# Docker-in-Docker specific initialization
if detect_dind; then
    echo "  🐳 Docker-in-Docker mode detected"
    
    # Wait for Docker to start
    echo "  🔄 Starting Docker daemon..."
    while ! pgrep "dockerd" >/dev/null; do
        sleep 1
    done
    echo "    ✓ Docker daemon started"
    
    # Fix Docker permissions
    if [ -f "/usr/local/bin/docker-compose" ]; then
        sudoIf chown ${USERNAME}:${USERNAME} /usr/local/bin/docker-compose
    fi
    sudoIf chown ${USERNAME}:${USERNAME} /var/run/docker.sock 2>/dev/null || true
    echo "    ✓ Docker permissions configured"
    
    # Terminal reset for DIND
    if [ -n "$TERM" ]; then
        tput cr 2>/dev/null || true
        reset -I 2>/dev/null || true
    fi
fi

echo
echo "✅ Base container initialized successfully"

# Execute the command or start interactive shell
execute_command "$@"