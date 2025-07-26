#!/usr/bin/env bash
set -e

# Check if mise has been initialized by looking for a marker file
MISE_INITIALIZED_MARKER="${HOME}/.local/share/mise/.initialized"

if [ -f "${MISE_INITIALIZED_MARKER}" ]; then
    exit 0
fi

echo "Initializing mise directories..."

# Ensure mise directories exist with correct permissions
mkdir -p "${HOME}/.cache/mise"
mkdir -p "${HOME}/.local/share/mise"
mkdir -p "${HOME}/.config/mise"

# Fix any legacy invalid system config if we have permission
if [ -w "/etc/mise/config.toml" ] && grep -q "node_compile\|bun_backend\|npm\.bun" /etc/mise/config.toml 2>/dev/null; then
    echo "Fixing legacy invalid system config..."
    cat > /etc/mise/config.toml << 'EOF'
[settings]
not_found_auto_install = true
experimental = true
EOF
fi

# Ensure user config is clean and add runtime
echo "Setting up mise config with runtime..."
# Preserve any existing tools but fix settings and add runtime
if [ -f "${HOME}/.config/mise/config.toml" ] && grep -q "\[tools\]" "${HOME}/.config/mise/config.toml" 2>/dev/null; then
    # Extract tools section and filter out any existing node/bun entries
    sed -n '/\[tools\]/,$p' "${HOME}/.config/mise/config.toml" | grep -v "^node\s*=" | grep -v "^bun\s*=" > /tmp/tools_section
else
    echo "[tools]" > /tmp/tools_section
fi

# Create new config with valid settings + runtime + any existing tools
cat > "${HOME}/.config/mise/config.toml" << 'EOF'
[settings]
not_found_auto_install = true
experimental = true

EOF

# Add Node.js LTS to tools section
echo "node = \"lts\"" >> /tmp/tools_section

cat /tmp/tools_section >> "${HOME}/.config/mise/config.toml"
rm -f /tmp/tools_section

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