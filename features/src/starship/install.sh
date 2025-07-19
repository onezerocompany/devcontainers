#!/bin/sh
set -e

VERSION="${VERSION:-latest}"
CONFIG_PATH="${CONFIGPATH:-}"

echo "Installing Starship prompt (version: $VERSION)..."

# Detect the OS and install dependencies
if [ -f /etc/alpine-release ]; then
    echo "Detected Alpine Linux"
    # Install required dependencies for Alpine
    apk add --no-cache \
        curl \
        bash \
        libc6-compat \
        ca-certificates
    # Create bash config directory if it doesn't exist
    mkdir -p /etc/bash
    touch /etc/bash/bashrc
fi

# Ensure curl is available and install if necessary
if ! command -v curl >/dev/null 2>&1; then
    echo "curl not found, installing..."
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update && apt-get install -y curl ca-certificates
    elif command -v apk >/dev/null 2>&1; then
        apk add --no-cache curl ca-certificates
    else
        echo "Error: curl is required but could not be installed automatically"
        exit 1
    fi
fi

# Determine the appropriate shell configuration files
SHELLS_TO_CONFIGURE=""
if [ -f /etc/bash.bashrc ]; then
    SHELLS_TO_CONFIGURE="$SHELLS_TO_CONFIGURE /etc/bash.bashrc"
elif [ -f /etc/bash/bashrc ]; then
    SHELLS_TO_CONFIGURE="$SHELLS_TO_CONFIGURE /etc/bash/bashrc"
fi
if [ -f /etc/zsh/zshrc ]; then
    SHELLS_TO_CONFIGURE="$SHELLS_TO_CONFIGURE /etc/zsh/zshrc"
fi

# For Alpine, also check profile files
if [ -f /etc/alpine-release ]; then
    if [ -f /etc/profile ]; then
        SHELLS_TO_CONFIGURE="$SHELLS_TO_CONFIGURE /etc/profile"
    fi
fi

# Install starship based on the version
if [ "$VERSION" = "latest" ]; then
    curl -sS https://starship.rs/install.sh | sh -s -- --yes
else
    curl -sS https://starship.rs/install.sh | sh -s -- --yes --version "$VERSION"
fi

# Configure shells to use starship
for SHELL_CONFIG in $SHELLS_TO_CONFIGURE; do
    if ! grep -q "starship init" "$SHELL_CONFIG" 2>/dev/null; then
        echo "" >> "$SHELL_CONFIG"
        echo "# Initialize Starship prompt" >> "$SHELL_CONFIG"
        case "$SHELL_CONFIG" in
            *bashrc*)
                echo 'eval "$(starship init bash)"' >> "$SHELL_CONFIG"
                ;;
            *zshrc*)
                echo 'eval "$(starship init zsh)"' >> "$SHELL_CONFIG"
                ;;
            */profile)
                # For profile, check if bash is available and use it
                echo 'if [ -n "$BASH_VERSION" ]; then' >> "$SHELL_CONFIG"
                echo '    eval "$(starship init bash)"' >> "$SHELL_CONFIG"
                echo 'elif [ -n "$ZSH_VERSION" ]; then' >> "$SHELL_CONFIG"
                echo '    eval "$(starship init zsh)"' >> "$SHELL_CONFIG"
                echo 'fi' >> "$SHELL_CONFIG"
                ;;
        esac
    fi
done

# Set up starship configuration
mkdir -p /etc/starship

# Copy custom configuration if provided, otherwise use default
if [ -n "$CONFIG_PATH" ] && [ -f "$CONFIG_PATH" ]; then
    echo "Copying custom starship configuration from $CONFIG_PATH..."
    cp "$CONFIG_PATH" /etc/starship/starship.toml
else
    echo "Using default starship configuration..."
    # Copy the default configuration from the feature directory
    cp "$(dirname "$0")/starship.toml" /etc/starship/starship.toml
fi

# Set environment variable for all users
# Create profile.d directory if it doesn't exist (for Alpine)
mkdir -p /etc/profile.d
echo 'export STARSHIP_CONFIG=/etc/starship/starship.toml' > /etc/profile.d/starship.sh
chmod +x /etc/profile.d/starship.sh

echo "Starship installation complete!"