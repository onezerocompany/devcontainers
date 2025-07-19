#!/bin/bash
set -e

# Script to configure shell environments for both bash and zsh
# Usage: configure-shells.sh <username>

# Script is self-contained - no external dependencies

USERNAME=$1

if [ -z "$USERNAME" ]; then
    echo "Error: USERNAME not provided"
    echo "Usage: $0 <username>"
    exit 1
fi

# Determine user home directory
if [ "$USERNAME" = "root" ]; then
    USER_HOME="/root"
else
    USER_HOME="/home/$USERNAME"
fi

echo "Configuring shells for $USERNAME..."

# Function to create shell configuration files
create_shell_configs() {
    local HOME_DIR=$1
    local USER=$2
    
    echo "  Creating shell configurations in $HOME_DIR for user $USER..."
    
    # Create common PATH export
    local PATH_EXPORT='export PATH="$HOME/.local/bin:$PATH"'
    
    # Create .bashrc
    cat > "$HOME_DIR/.bashrc" << EOF
# Path configuration
$PATH_EXPORT

# Basic aliases
alias apt-get='apt-fast'

# Mise activation (tool management)
if [ -f "\$HOME/.local/bin/mise" ]; then
    eval "\$(\$HOME/.local/bin/mise activate bash)"
fi

# Starship prompt
if command -v starship >/dev/null 2>&1; then
    eval "\$(starship init bash)"
fi

# Zoxide (smart cd)
if command -v zoxide >/dev/null 2>&1; then
    eval "\$(zoxide init bash)"
fi
EOF

    # Create .bash_profile
    cat > "$HOME_DIR/.bash_profile" << EOF
# Path configuration for login shells
$PATH_EXPORT

# Source .bashrc if it exists
if [ -f "\$HOME/.bashrc" ]; then
    source "\$HOME/.bashrc"
fi

# Source mise env for login shells
if [ -f "\$HOME/.local/bin/mise" ]; then
    eval "\$(\$HOME/.local/bin/mise activate bash --shims)"
fi
EOF

    # Create .zshenv
    cat > "$HOME_DIR/.zshenv" << EOF
# Path configuration for non-interactive shells
$PATH_EXPORT

# Source mise env for non-interactive shells
if [ -f "\$HOME/.local/bin/mise" ]; then
    eval "\$(\$HOME/.local/bin/mise activate zsh --shims)"
fi
EOF

    # Create .zprofile
    cat > "$HOME_DIR/.zprofile" << EOF
# Path configuration for login shells
$PATH_EXPORT

# Source mise env for login shells
if [ -f "\$HOME/.local/bin/mise" ]; then
    eval "\$(\$HOME/.local/bin/mise activate zsh --shims)"
fi
EOF

    # Create .zshrc
    cat > "$HOME_DIR/.zshrc" << 'EOF'
# Base image shell configuration
# Ensure PATH includes .local/bin for mise
export PATH="$HOME/.local/bin:$PATH"

# Zsh completion system
autoload -Uz compinit
compinit

# Basic aliases
alias apt-get='apt-fast'

# Mise activation (tool management)
if [ -f "$HOME/.local/bin/mise" ]; then
    eval "$($HOME/.local/bin/mise activate zsh)"
    # Also ensure shims are in PATH for installed tools
    eval "$($HOME/.local/bin/mise activate zsh --shims)"
fi

# Starship prompt
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi

# Zoxide (smart cd)
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi

# Note: Additional configuration may be added by devcontainer image
EOF

    # Set ownership if not root
    if [ "$USER" != "root" ]; then
        chown -R "$USER:$USER" "$HOME_DIR/.bashrc" "$HOME_DIR/.bash_profile" \
            "$HOME_DIR/.zshenv" "$HOME_DIR/.zprofile" "$HOME_DIR/.zshrc"
    fi
}

# Create shell configurations for the specified user
create_shell_configs "$USER_HOME" "$USERNAME"

# Also create for root if we're running as root and configuring another user
if [ "$EUID" -eq 0 ] && [ "$USERNAME" != "root" ]; then
    echo "  Also creating shell configurations for root..."
    create_shell_configs "/root" "root"
fi


# Note: Shell is already set to zsh when user is created in Dockerfile
# This is just a fallback in case it wasn't set properly
echo "  Verifying shell settings for $USERNAME..."
CURRENT_SHELL=$(getent passwd "$USERNAME" | cut -d: -f7)
if [ "$CURRENT_SHELL" != "/bin/zsh" ]; then
    echo "    Updating shell from $CURRENT_SHELL to /bin/zsh for $USERNAME..."
    if [ "$USERNAME" = "root" ]; then
        chsh -s /bin/zsh
    else
        chsh -s /bin/zsh "$USERNAME"
    fi
fi

# If running as root and configuring another user, also verify root's shell
if [ "$EUID" -eq 0 ] && [ "$USERNAME" != "root" ]; then
    ROOT_SHELL=$(getent passwd root | cut -d: -f7)
    if [ "$ROOT_SHELL" != "/bin/zsh" ]; then
        echo "    Updating shell from $ROOT_SHELL to /bin/zsh for root..."
        chsh -s /bin/zsh
    fi
fi

echo "Shell configuration completed for user $USERNAME"