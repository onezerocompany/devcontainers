#!/bin/bash
# Common utilities for devcontainer scripts
# This file contains shared functions to reduce code duplication

# Add a directory to PATH if it exists and isn't already in PATH
add_to_path() {
    local dir="$1"
    if [ -d "$dir" ] && [[ ":$PATH:" != *":$dir:"* ]]; then
        export PATH="$dir:$PATH"
    fi
}

# Configure PATH for all shells
configure_path() {
    local path_line="export PATH=\"\$HOME/.local/bin:\$PATH\""
    
    # Add to bash configs
    if [ -f "$HOME/.bashrc" ]; then
        grep -qF "$path_line" "$HOME/.bashrc" || echo "$path_line" >> "$HOME/.bashrc"
    fi
    
    # Add to zsh configs
    if [ -f "$HOME/.zshenv" ]; then
        grep -qF "$path_line" "$HOME/.zshenv" || echo "$path_line" >> "$HOME/.zshenv"
    fi
}

# Run command as sudo only if not already root
sudoIf() {
    if [ "$(id -u)" -ne 0 ]; then
        sudo "$@"
    else
        "$@"
    fi
}

# Common entrypoint execution logic
execute_command() {
    if [ $# -eq 0 ]; then
        # No command provided
        if [ -t 0 ]; then
            # Interactive terminal - start shell
            exec zsh -l
        else
            # Non-interactive - keep container running
            exec tail -f /dev/null
        fi
    else
        # Execute provided command
        exec "$@"
    fi
}

# Wait for Docker daemon to be ready
wait_for_docker() {
    local max_attempts=30
    local attempt=0
    
    echo "Waiting for Docker daemon to start..."
    while ! docker version >/dev/null 2>&1; do
        attempt=$((attempt + 1))
        if [ $attempt -gt $max_attempts ]; then
            echo "Docker daemon failed to start after $max_attempts attempts"
            return 1
        fi
        sleep 1
    done
    echo "Docker daemon is ready"
    return 0
}

# Fix Docker socket permissions
fix_docker_permissions() {
    local docker_socket="/var/run/docker.sock"
    if [ -S "$docker_socket" ]; then
        sudoIf chmod 666 "$docker_socket"
    fi
}

# Initialize Docker if running in Docker-in-Docker mode
init_docker_if_needed() {
    if [ -f /.dockerenv ] && [ -x "$(command -v dockerd)" ]; then
        # Check if Docker daemon is already running
        if ! docker version >/dev/null 2>&1; then
            echo "Starting Docker daemon..."
            sudoIf dockerd &
            
            # Wait for Docker to be ready
            if wait_for_docker; then
                fix_docker_permissions
            else
                echo "Warning: Docker daemon initialization failed"
            fi
        fi
    fi
}