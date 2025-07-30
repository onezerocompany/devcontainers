#!/usr/bin/env bash
set -e

# Check if mise has been initialized by looking for a marker file
MISE_INITIALIZED_MARKER="${HOME}/.local/share/mise/.initialized"

if [ -f "${MISE_INITIALIZED_MARKER}" ]; then
    exit 0
fi

echo "Initializing mise directories..."

# Ensure mise directories exist with correct permissions
mkdir -p "${HOME}/.local/share/mise"
mkdir -p "${HOME}/.config/mise"
mkdir -p "${HOME}/.local/bin"
mkdir -p "${HOME}/.cache/mise"
mkdir -p "${HOME}/.local/state/mise"
mkdir -p "${HOME}/.bun/bin"

# Ensure directories are owned by the current user
if [ "$(stat -c %u "${HOME}/.local/share/mise" 2>/dev/null)" != "$(id -u)" ]; then
    echo "Fixing ownership for mise directories..."
    # Try to fix ownership if we can
    if command -v sudo >/dev/null 2>&1; then
        sudo chown -R "$(id -u):$(id -g)" "${HOME}/.local/share/mise" 2>/dev/null || true
        sudo chown -R "$(id -u):$(id -g)" "${HOME}/.config/mise" 2>/dev/null || true
        sudo chown -R "$(id -u):$(id -g)" "${HOME}/.cache/mise" 2>/dev/null || true
        sudo chown -R "$(id -u):$(id -g)" "${HOME}/.local/state/mise" 2>/dev/null || true
        sudo chown -R "$(id -u):$(id -g)" "${HOME}/.bun" 2>/dev/null || true
    fi
fi

# Ensure all mise subdirectories have correct permissions
mkdir -p "${HOME}/.local/share/mise/installs"
mkdir -p "${HOME}/.local/share/mise/cache"
mkdir -p "${HOME}/.local/share/mise/downloads"
mkdir -p "${HOME}/.cache/mise/lockfiles"
mkdir -p "${HOME}/.cache/mise/node"

# Ensure bun directories have correct permissions
chmod 755 "${HOME}/.bun" 2>/dev/null || true
chmod 755 "${HOME}/.bun/bin" 2>/dev/null || true


# Fix any legacy invalid system config if we have permission
if [ -w "/etc/mise/config.toml" ] && grep -q "node_compile\|bun_backend\|npm\.bun" /etc/mise/config.toml 2>/dev/null; then
    echo "Fixing legacy invalid system config..."
    cat > /etc/mise/config.toml << 'EOF'
[settings]
not_found_auto_install = true
experimental = true
EOF
fi

# Set up mise config if it doesn't exist
if [ ! -f "${HOME}/.config/mise/config.toml" ]; then
    echo "Setting up mise config..."
    # Check mise version to determine which settings to use
    MISE_VERSION_OUTPUT=$(mise --version 2>/dev/null || echo "")
    if echo "${MISE_VERSION_OUTPUT}" | grep -q "2024\.1\." || echo "${MISE_VERSION_OUTPUT}" | grep -q "2023\."; then
        # Older mise version - use minimal config
        cat > "${HOME}/.config/mise/config.toml" << EOF
[settings]
experimental = true

[env]
BUN_INSTALL = "${HOME}/.bun"
EOF
    else
        # Newer mise version - use full config
        cat > "${HOME}/.config/mise/config.toml" << EOF
[settings]
not_found_auto_install = true
experimental = true

[env]
BUN_INSTALL = "${HOME}/.bun"
EOF
    fi
fi

# Auto-trust directories if enabled
if [ "${MISE_AUTO_TRUST}" = "true" ]; then
    # Auto-trust the workspace directory
    if [ -n "${WORKSPACE_DIR}" ]; then
        echo "Auto-trusting workspace directory: ${WORKSPACE_DIR}"
        mise trust "${WORKSPACE_DIR}" 2>/dev/null || true
    elif [ -d "/workspaces" ]; then
        # Common devcontainer workspace location
        echo "Auto-trusting /workspaces directory"
        mise trust "/workspaces" 2>/dev/null || true
    fi
    
    # Auto-trust /workspace if it exists (common in devcontainers)
    if [ -d "/workspace" ]; then
        echo "Auto-trusting /workspace directory"
        mise trust "/workspace" 2>/dev/null || true
    fi

    # Auto-trust current working directory if it has .mise.toml
    if [ -f "$(pwd)/.mise.toml" ]; then
        echo "Auto-trusting current directory: $(pwd)"
        mise trust "$(pwd)" 2>/dev/null || true
    fi

    # Also trust the home directory if it has a .mise.toml
    if [ -f "${HOME}/.mise.toml" ]; then
        echo "Auto-trusting home directory: ${HOME}"
        mise trust "${HOME}" 2>/dev/null || true
    fi
fi

# Create marker file to indicate initialization is complete
touch "${MISE_INITIALIZED_MARKER}"

echo "mise initialization complete!"