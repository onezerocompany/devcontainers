#!/bin/bash
set -e

echo "Configuring shells for devcontainer..."

# Create a marker to track if devcontainer config has been applied
DEVCONTAINER_MARKER="# DEVCONTAINER_CONFIG_APPLIED"

# Check if configuration already applied by looking for our marker
if grep -q "$DEVCONTAINER_MARKER" ~/.zshrc 2>/dev/null; then
    echo "DevContainer shell configuration already applied."
    exit 0
fi

# DevContainer-specific configuration that will be appended to existing shell configs
# Note: We use single quotes to prevent variable expansion during assignment
read -r -d '' DEVCONTAINER_CONFIG << 'EOF' || true

# DEVCONTAINER_CONFIG_APPLIED
# DevContainer specific configuration
# Ensure mise tools are in PATH first
export PATH="$HOME/.local/bin:$PATH"

# Display MOTD only in interactive shells with proper terminal
if [[ -o interactive ]] && [[ -t 0 ]] && [[ "$TERM" != "dumb" ]]; then
    if [ -f /etc/motd ]; then cat /etc/motd; fi
fi

# Shell options
setopt auto_cd 2>/dev/null || true  # zsh only

# Re-activate mise to ensure tools are available with shims
if [ -f "$HOME/.local/bin/mise" ]; then
    eval "$($HOME/.local/bin/mise activate ${SHELL##*/})"
    # Also ensure shims are in PATH for installed tools
    eval "$($HOME/.local/bin/mise activate ${SHELL##*/} --shims)"
fi

# Tool initialization (these require mise-installed tools to be in PATH)
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init --cmd cd ${SHELL##*/})"
fi

# Aliases for modern CLI tools
if command -v batcat >/dev/null 2>&1; then
    alias cat="batcat"
elif command -v bat >/dev/null 2>&1; then
    alias cat="bat"
fi

if command -v eza >/dev/null 2>&1; then
    alias ls="eza"
    alias ll="eza -l"
    alias la="eza -la"
fi

# Mise tools alias
alias tools="mise ls --current"

# Initialize starship prompt (must be last)
# Try multiple methods to find starship
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init ${SHELL##*/})"
elif [ -x "$HOME/.local/share/mise/installs/starship/latest/bin/starship" ]; then
    eval "$($HOME/.local/share/mise/installs/starship/latest/bin/starship init ${SHELL##*/})"
elif [ -x "$HOME/.local/share/mise/shims/starship" ]; then
    eval "$($HOME/.local/share/mise/shims/starship init ${SHELL##*/})"
else
    # Try to find starship in any mise installation
    STARSHIP_PATH=$(find "$HOME/.local/share/mise/installs/starship" -name "starship" -type f -executable 2>/dev/null | head -1)
    if [ -n "$STARSHIP_PATH" ] && [ -x "$STARSHIP_PATH" ]; then
        eval "$($STARSHIP_PATH init ${SHELL##*/})"
    else
        echo "Warning: starship not found. Run 'mise install' to install tools."
    fi
fi
EOF

# Function to append config to shell file
append_to_shell_config() {
    local shell_file="$1"
    local shell_type="$2"
    
    # Create file if it doesn't exist (especially for .bashrc)
    if [ ! -f "$shell_file" ]; then
        echo "# Shell configuration for $shell_type" > "$shell_file"
        echo "Created $(basename "$shell_file")"
    fi
    
    # Append devcontainer configuration
    echo "" >> "$shell_file"
    echo "$DEVCONTAINER_CONFIG" >> "$shell_file"
    echo "Updated $(basename "$shell_file") with devcontainer configuration"
}

# Apply to both shells
append_to_shell_config ~/.zshrc "zsh"
append_to_shell_config ~/.bashrc "bash"

echo "Shell configuration complete."