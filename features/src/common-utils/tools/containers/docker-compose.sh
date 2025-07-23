#!/bin/bash
# Docker Compose installation
set -e

install_docker_compose() {
    # Check if this tool should be installed
    if [ "${DOCKERCOMPOSE:-false}" != "true" ]; then
        echo "  ⏭️  Skipping Docker Compose installation (disabled)"
        return 0
    fi

    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${SCRIPT_DIR}/../../lib/utils.sh"

    echo "  🔧 Installing Docker Compose..."
    if ! command -v docker-compose >/dev/null 2>&1; then
        # Get latest version dynamically
        local version
        version=$(get_latest_github_release "docker/compose")
        if [ -z "$version" ]; then
            echo "  ⚠️  Failed to get latest version, using fallback"
            version="2.24.3"
        fi
        
        local arch
        arch=$(get_architecture)
        local compose_arch
        if [ "$arch" = "amd64" ]; then
            compose_arch="linux-x86_64"
        elif [ "$arch" = "arm64" ]; then
            compose_arch="linux-aarch64"
        else
            echo "  ⚠️  Unsupported architecture: $arch"
            return 1
        fi
        
        local url="https://github.com/docker/compose/releases/download/v${version}/docker-compose-${compose_arch}"
        local install_path="/usr/local/bin/docker-compose"
        
        echo "  📥 Downloading Docker Compose v${version}..."
        if secure_download "$url" "$install_path"; then
            chmod +x "$install_path"
            # Verify the binary works
            if "$install_path" version >/dev/null 2>&1; then
                echo "  ✅ Docker Compose v${version} installed and verified successfully"
            else
                echo "  ⚠️ Docker Compose installed but may not be functional"
            fi
        else
            echo "  ❌ Failed to download Docker Compose"
            return 1
        fi
    else
        echo "  ✅ Docker Compose already installed"
    fi
}

# Execute the installation function
install_docker_compose