#!/bin/bash
# Playwright Installation Script

set -e

export DEBIAN_FRONTEND=noninteractive

# Feature options
VERSION="${VERSION:-latest}"
BROWSERS="${BROWSERS:-chromium firefox webkit}"
INSTALL_DEPS="${INSTALL_DEPS:-true}"

echo "Installing Playwright..."

# Update package list
apt-get update

# Install basic dependencies
apt-get install -y \
    ca-certificates \
    curl \
    wget \
    unzip

# Use mise to install Playwright via npm backend
if ! command -v mise &> /dev/null; then
    echo "ERROR: mise not found!"
    echo "Please install the 'mise-en-place' feature before using the Playwright feature."
    exit 1
fi

echo "Using mise npm backend to install Playwright..."

# Ensure npm is available through mise
if ! mise exec -- npm --version &> /dev/null; then
    echo "Installing Node.js via mise to get npm..."
    mise use -g node@lts
fi

# Install Playwright globally via mise npm backend
if [ "$VERSION" = "latest" ]; then
    mise exec -- npm install -g playwright
else
    mise exec -- npm install -g playwright@$VERSION
fi

PLAYWRIGHT_CMD="mise exec -- npx playwright"

# Create the browsers directory
mkdir -p /ms-playwright

# Set the browsers path environment variable for the installation
export PLAYWRIGHT_BROWSERS_PATH=/ms-playwright

# Install browsers
echo "Installing Playwright browsers: $BROWSERS"
if [ "$INSTALL_DEPS" = "true" ]; then
    echo "Installing browsers with system dependencies..."
    $PLAYWRIGHT_CMD install $BROWSERS --with-deps
else
    echo "Installing browsers without system dependencies..."
    $PLAYWRIGHT_CMD install $BROWSERS
fi

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
echo "Browsers installed: $BROWSERS"
if [ "$INSTALL_DEPS" = "true" ]; then
    echo "System dependencies were installed"
else
    echo "System dependencies were skipped"
fi

exit 0