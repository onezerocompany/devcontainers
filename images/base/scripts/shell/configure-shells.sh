#!/bin/bash
# Shell configuration script for devcontainer base image
# Configures both bash and zsh with modern CLI tools and utilities
# Usage: configure-shells.sh <username>
set -e

# ========================================
# VALIDATION
# ========================================

USERNAME=$1

if [ -z "$USERNAME" ]; then
    echo "Error: USERNAME not provided"
    echo "Usage: $0 <username>"
    exit 1
fi

# ========================================
# SETUP
# ========================================

# Determine user home directory
if [ "$USERNAME" = "root" ]; then
    USER_HOME="/root"
else
    USER_HOME="/home/$USERNAME"
fi

echo "Configuring shells for $USERNAME..."

# ========================================
# SHELL CONFIGURATION FUNCTION
# ========================================

create_shell_configs() {
    local HOME_DIR=$1
    local USER=$2
    
    echo "  Creating shell configurations in $HOME_DIR for user $USER..."
    
    # Common PATH configuration
    local PATH_EXPORT='export PATH="$HOME/.local/bin:$PATH"'
    
    # ----------------------------------------
    # BASH CONFIGURATION
    # ----------------------------------------
    
    # Create .bashrc
    cat > "$HOME_DIR/.bashrc" << EOF
# Bash configuration for devcontainer

# Path configuration
$PATH_EXPORT

# Package manager optimization
alias apt-get='apt-fast'

# Tool activation: Mise (runtime version manager)
if [ -f "\$HOME/.local/bin/mise" ]; then
    eval "\$(\$HOME/.local/bin/mise activate bash)"
fi

# Modern CLI tools
# Starship - Cross-shell prompt
if command -v starship >/dev/null 2>&1; then
    eval "\$(starship init bash)"
fi

# Zoxide - Smarter cd command
if command -v zoxide >/dev/null 2>&1; then
    eval "\$(zoxide init bash)"
fi
EOF

    # Create .bash_profile
    cat > "$HOME_DIR/.bash_profile" << EOF
# Bash profile for login shells

# Path configuration
$PATH_EXPORT

# Source .bashrc for interactive functionality
if [ -f "\$HOME/.bashrc" ]; then
    source "\$HOME/.bashrc"
fi

# Mise shims for login shells
if [ -f "\$HOME/.local/bin/mise" ]; then
    eval "\$(\$HOME/.local/bin/mise activate bash --shims)"
fi
EOF

    # ----------------------------------------
    # ZSH CONFIGURATION
    # ----------------------------------------

    # Create .zshenv (sourced for all zsh instances)
    cat > "$HOME_DIR/.zshenv" << EOF
# Zsh environment configuration (all shells)

# Path configuration
$PATH_EXPORT

# Mise shims for non-interactive shells
if [ -f "\$HOME/.local/bin/mise" ]; then
    eval "\$(\$HOME/.local/bin/mise activate zsh --shims)"
fi
EOF

    # Create .zprofile (sourced for login shells)
    cat > "$HOME_DIR/.zprofile" << EOF
# Zsh profile for login shells

# Path configuration
$PATH_EXPORT

# Mise environment for login shells
if [ -f "\$HOME/.local/bin/mise" ]; then
    eval "\$(\$HOME/.local/bin/mise activate zsh --shims)"
fi
EOF

    # Create .zshrc (sourced for interactive shells)
    cat > "$HOME_DIR/.zshrc" << 'EOF'
# Zsh configuration for devcontainer

# Path configuration
export PATH="$HOME/.local/bin:$PATH"

# Enable Zsh completion system
autoload -Uz compinit
compinit

# Package manager optimization
alias apt-get='apt-fast'

# Tool activation: Mise (runtime version manager)
if [ -f "$HOME/.local/bin/mise" ]; then
    eval "$($HOME/.local/bin/mise activate zsh)"
    # Ensure shims are available for installed tools
    eval "$($HOME/.local/bin/mise activate zsh --shims)"
fi

# Modern CLI tools
# Starship - Cross-shell prompt
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi

# Zoxide - Smarter cd command
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi

# Additional configurations can be added by extending images
EOF

    # ----------------------------------------
    # OWNERSHIP
    # ----------------------------------------
    
    # Set proper ownership for non-root users
    if [ "$USER" != "root" ]; then
        chown -R "$USER:$USER" "$HOME_DIR/.bashrc" "$HOME_DIR/.bash_profile" \
            "$HOME_DIR/.zshenv" "$HOME_DIR/.zprofile" "$HOME_DIR/.zshrc"
    fi
}

# ========================================
# MAIN EXECUTION
# ========================================

# Configure shells for the specified user
create_shell_configs "$USER_HOME" "$USERNAME"

# Also configure root if we're running as root and configuring another user
if [ "$EUID" -eq 0 ] && [ "$USERNAME" != "root" ]; then
    echo "  Also creating shell configurations for root..."
    create_shell_configs "/root" "root"
fi

# ========================================
# SHELL VERIFICATION
# ========================================

echo "  Verifying shell settings..."

# Verify the user's default shell
CURRENT_SHELL=$(getent passwd "$USERNAME" | cut -d: -f7)
if [ "$CURRENT_SHELL" != "/bin/zsh" ]; then
    echo "    Updating default shell to /bin/zsh for $USERNAME..."
    if [ "$USERNAME" = "root" ]; then
        chsh -s /bin/zsh
    else
        chsh -s /bin/zsh "$USERNAME"
    fi
fi

# Also verify root's shell if we're configuring another user
if [ "$EUID" -eq 0 ] && [ "$USERNAME" != "root" ]; then
    ROOT_SHELL=$(getent passwd root | cut -d: -f7)
    if [ "$ROOT_SHELL" != "/bin/zsh" ]; then
        echo "    Updating default shell to /bin/zsh for root..."
        chsh -s /bin/zsh
    fi
fi

echo "✅ Shell configuration completed for user $USERNAME"