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

# Wait for Docker daemon to be ready
wait_for_docker() {
    local max_attempts=30
    local attempt=0
    
    echo "🔄 Waiting for Docker daemon to start..."
    while ! docker version >/dev/null 2>&1; do
        attempt=$((attempt + 1))
        if [ $attempt -gt $max_attempts ]; then
            echo "  ❌ Docker daemon failed to start after $max_attempts attempts."
            return 1
        fi
        sleep 1
    done
    echo "  ✅ Docker daemon is ready."
    return 0
}

# Fix Docker socket permissions
fix_docker_permissions() {
    local docker_socket="/var/run/docker.sock"
    if [ -S "$docker_socket" ]; then
        sudoIf chmod 666 "$docker_socket"
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

# Initialize Docker if running in Docker-in-Docker mode
init_docker_if_needed() {
    if [ -f /.dockerenv ] && [ -x "$(command -v dockerd)" ]; then
        # Check if Docker daemon is already running
        if ! docker version >/dev/null 2>&1; then
            echo "🔄 Starting Docker daemon..."
            sudoIf dockerd &
            
            # Wait for Docker to be ready
            if wait_for_docker; then
                fix_docker_permissions
            else
                echo "  ⚠️ Warning: Docker daemon initialization failed."
            fi
        fi
    fi
}

# JavaScript runtime detection utility
detect_js_runtime() {
    local runtime=""
    local package_manager=""
    
    # Check for Bun
    if [ -f "bun.lockb" ] || [ -f "bun.lock" ] || [ -f "bunfig.toml" ]; then
        runtime="bun"
        package_manager="bun"
    # Check for Deno
    elif [ -f "deno.json" ] || [ -f "deno.jsonc" ] || [ -f "import_map.json" ]; then
        runtime="deno"
        package_manager="deno"
    # Check for Node.js
    elif [ -f "package.json" ]; then
        runtime="node"
        
        # Determine package manager for Node.js projects
        if [ -f "bun.lockb" ] || [ -f "bun.lock" ]; then
            package_manager="bun"
        elif [ -f "pnpm-lock.yaml" ]; then
            package_manager="pnpm"
        elif [ -f "yarn.lock" ]; then
            package_manager="yarn"
        elif [ -f "package-lock.json" ]; then
            package_manager="npm"
        else
            package_manager="npm"  # Default to npm if no lock file
        fi
    fi
    
    # Output results
    if [ -n "$runtime" ]; then
        echo "RUNTIME=$runtime"
        echo "PACKAGE_MANAGER=$package_manager"
        return 0
    else
        return 1
    fi
}

# Install JavaScript dependencies based on detected runtime
install_js_dependencies() {
    local runtime=""
    local package_manager=""
    
    # Source the detection results
    eval "$(detect_js_runtime)"
    
    if [ -z "$runtime" ]; then
        return 1
    fi
    
    echo "  📦 Detected $runtime project..."
    
    case "$runtime" in
        "bun")
            if command -v bun &> /dev/null; then
                echo "    Installing dependencies with Bun..."
                bun install 2>&1 || echo "    ⚠️  Warning: Failed to install dependencies"
                echo "    ✓ Bun dependencies installed"
            else
                echo "    ⚠️  Warning: Bun not found, skipping dependency installation"
                return 1
            fi
            ;;
            
        "deno")
            if command -v deno &> /dev/null; then
                echo "    Caching dependencies with Deno..."
                if [ -f "deno.json" ] || [ -f "deno.jsonc" ]; then
                    deno cache --reload --lock=deno.lock $(find . -name "*.ts" -o -name "*.js" -o -name "*.tsx" -o -name "*.jsx" | head -10) 2>&1 || echo "    ⚠️  Warning: Failed to cache some dependencies"
                fi
                echo "    ✓ Deno dependencies cached"
            else
                echo "    ⚠️  Warning: Deno not found, skipping dependency caching"
                return 1
            fi
            ;;
            
        "node")
            echo "    Installing dependencies with $package_manager..."
            case "$package_manager" in
                "bun") bun install ;;
                "pnpm") pnpm install ;;
                "yarn") yarn install ;;
                "npm") npm install ;;
                *) echo "Unsupported package manager: $package_manager"; exit 1 ;;
            esac
            echo "    ✓ Dependencies installed with $package_manager"
            ;;
    esac
    
    return 0
}