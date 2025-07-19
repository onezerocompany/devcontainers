#!/bin/bash
set -e

echo "🚀 Setting up development environment..."
echo

# Define required functions directly
add_to_path() {
    local dir="$1"
    if [ -d "$dir" ] && [[ ":$PATH:" != *":$dir:"* ]]; then
        export PATH="$dir:$PATH"
    fi
}

# Check for mise configuration files in all possible locations
# Order matters - more specific files take precedence
MISE_CONFIG_FILES=(
    ".mise.local.toml"
    "mise.local.toml"
    ".mise.\${MISE_ENV}.toml"  # Will be evaluated if MISE_ENV is set
    "mise.\${MISE_ENV}.toml"    # Will be evaluated if MISE_ENV is set
    ".mise.toml"
    ".mise/config.toml"
    "mise.toml"
    "mise/config.toml"
    ".config/mise.toml"
    ".config/mise/config.toml"
    ".tool-versions"  # Legacy asdf format
)

# Function to check if any mise config exists
has_mise_config() {
    for config in "${MISE_CONFIG_FILES[@]}"; do
        # Expand environment variables in config name
        expanded_config=$(eval echo "$config")
        if [ -f "$expanded_config" ]; then
            return 0
        fi
    done
    return 1
}

# Install project-specific mise tools if any config exists
if command -v mise &> /dev/null && has_mise_config; then
    echo "  📦 Installing project-specific tools..."
    # List which config files were found
    for config in "${MISE_CONFIG_FILES[@]}"; do
        expanded_config=$(eval echo "$config")
        if [ -f "$expanded_config" ]; then
            echo "    📄 Found: $expanded_config"
        fi
    done
    # Suppress TERM warnings by setting a minimal TERM if not set
    if [ -z "$TERM" ]; then
        export TERM=dumb
    fi
    mise trust --all 2>&1
    mise install --yes 2>&1
    echo
    echo "    ✓ Project tools installed"
elif has_mise_config; then
    echo "  ⚠️  Warning: mise not found, skipping project tool installation"
fi

# Detect JavaScript runtime and install packages
install_js_dependencies

# Initialize sandbox (using shared script from base image)
if [ -x "/usr/local/bin/init-sandbox" ]; then
    echo "  🛠️ Initializing sandbox environment..."
    /usr/local/bin/init-sandbox
    echo
fi

echo
# The MOTD will be displayed when the shell starts
echo "✨ DevContainer is ready!"