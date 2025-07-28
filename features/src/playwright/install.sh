#!/bin/bash
# Playwright Installation Script

set -e

export DEBIAN_FRONTEND=noninteractive

# Feature options
VERSION="${VERSION:-latest}"

echo "Installing Playwright..."

# Update package list
apt-get update

# Install basic dependencies
apt-get install -y \
    ca-certificates \
    curl \
    wget \
    unzip

# Check for bun first (preferred), then fallback to npm
if command -v bun >/dev/null 2>&1; then
    echo "Installing Playwright globally with bun..."
    if [ "$VERSION" = "latest" ]; then
        bun add -g playwright
    else
        bun add -g playwright@$VERSION
    fi
    PLAYWRIGHT_CMD="bunx playwright"
elif command -v npm >/dev/null 2>&1; then
    echo "Installing Playwright globally with npm..."
    if [ "$VERSION" = "latest" ]; then
        npm install -g playwright
    else
        npm install -g playwright@$VERSION
    fi
    PLAYWRIGHT_CMD="npx playwright"
else
    echo "Error: Neither bun nor npm found. Please install one of them first."
    exit 1
fi

# Install all browsers with dependencies + ffmpeg
echo "Installing all Playwright browsers with dependencies and ffmpeg..."
$PLAYWRIGHT_CMD install chromium firefox webkit --with-deps

# Determine the user
USERNAME="${_REMOTE_USER:-"automatic"}"
if [ "${USERNAME}" = "auto" ] || [ "${USERNAME}" = "automatic" ]; then
    USERNAME=""
    local uid_1000_user
    uid_1000_user=$(awk -v val=1000 -F ":" '$3==val{print $1; exit}' /etc/passwd | head -n1)
    local possible_users
    if [ -n "$uid_1000_user" ] && [[ "$uid_1000_user" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        possible_users=("zero" "vscode" "node" "codespace" "$uid_1000_user")
    else
        possible_users=("zero" "vscode" "node" "codespace")
    fi
    for current_user in "${possible_users[@]}"; do
        if id -u "${current_user}" > /dev/null 2>&1; then
            USERNAME="${current_user}"
            break
        fi
    done
    if [ -z "${USERNAME}" ]; then
        USERNAME="root"
    fi
elif [ "${USERNAME}" = "none" ] || [ "${USERNAME}" = "root" ]; then
    USERNAME="root"
fi

USER_HOME=$(getent passwd "$USERNAME" | cut -d: -f6)

echo "Setting up environment variables for user: $USERNAME"

# Set up environment variables for both bash and zsh
setup_shell_env() {
    local user="$1"
    local home_dir="$2"
    
    # Ensure .bashrc exists
    if [ ! -f "$home_dir/.bashrc" ]; then
        touch "$home_dir/.bashrc"
    fi
    
    # Ensure .zshrc exists  
    if [ ! -f "$home_dir/.zshrc" ]; then
        touch "$home_dir/.zshrc"
    fi
    
    # Add Playwright environment variables to .bashrc
    if ! grep -q "PLAYWRIGHT_BROWSERS_PATH" "$home_dir/.bashrc"; then
        echo "" >> "$home_dir/.bashrc"
        echo "# Playwright environment variables" >> "$home_dir/.bashrc"
        echo "export PLAYWRIGHT_BROWSERS_PATH=/ms-playwright" >> "$home_dir/.bashrc"
        echo "export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=0" >> "$home_dir/.bashrc"
    fi
    
    # Add Playwright environment variables to .zshrc
    if ! grep -q "PLAYWRIGHT_BROWSERS_PATH" "$home_dir/.zshrc"; then
        echo "" >> "$home_dir/.zshrc"
        echo "# Playwright environment variables" >> "$home_dir/.zshrc"
        echo "export PLAYWRIGHT_BROWSERS_PATH=/ms-playwright" >> "$home_dir/.zshrc"
        echo "export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=0" >> "$home_dir/.zshrc"
    fi
    
    # Set proper ownership if not root
    if [ "$user" != "root" ] && id "$user" &>/dev/null; then
        chown "$user:$user" "$home_dir/.bashrc" 2>/dev/null || true
        chown "$user:$user" "$home_dir/.zshrc" 2>/dev/null || true
    fi
}

# Configure for the main user
setup_shell_env "$USERNAME" "$USER_HOME"

# Configure for root as well
setup_shell_env "root" "/root"

# Also create the profile script for system-wide access
cat > /etc/profile.d/playwright.sh << 'EOF'
export PLAYWRIGHT_BROWSERS_PATH=/ms-playwright
export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=0
EOF

chmod +x /etc/profile.d/playwright.sh

# Clean up
apt-get autoremove -y
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "Playwright installation complete!"
echo "All browsers (chromium, firefox, webkit) installed with dependencies and ffmpeg"

exit 0