#!/bin/bash
# Unified entrypoint for base image containers
# Handles both standard and Docker-in-Docker variants

set -e

# Source common utilities
source /usr/local/bin/common-utils.sh

USERNAME="${USERNAME:-zero}"

# Main initialization
echo "🚀 Initializing container..."
echo

# Docker-in-Docker specific initialization
if detect_dind; then
    echo "  🐳 Docker-in-Docker mode detected"
    
    # Start supervisor for Docker daemon
    sudoIf /usr/bin/supervisord -c /etc/supervisor/supervisord.conf -n >> /dev/null 2>&1 &
    
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