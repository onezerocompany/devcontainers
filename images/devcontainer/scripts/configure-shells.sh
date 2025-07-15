#!/bin/bash
set -e

echo "Configuring shells for devcontainer..."

# Check if starship initialization already exists (more specific check)
if grep -q "starship init" ~/.zshrc 2>/dev/null && 
   grep -q "starship init" ~/.bashrc 2>/dev/null; then
    echo "Starship configuration already applied."
    exit 0
fi

# DevContainer-specific configuration that will be appended to existing shell configs
DEVCONTAINER_CONFIG='
# DevContainer specific configuration
# Ensure mise tools are in PATH first
export PATH="$HOME/.local/bin:$PATH"

# Display MOTD only in interactive shells with proper terminal
if [[ -o interactive ]] && [[ -t 0 ]] && [[ "$TERM" != "dumb" ]]; then
    if [ -f /etc/motd ]; then cat /etc/motd; fi
fi

# Shell options
setopt auto_cd 2>/dev/null || true  # zsh only

# Re-activate mise to ensure tools are available
if [ -f "$HOME/.local/bin/mise" ]; then
    eval "$($HOME/.local/bin/mise activate ${SHELL##*/})"
fi

# Tool initialization (these require mise-installed tools to be in PATH)
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init --cmd cd ${SHELL##*/})"
fi

# Aliases for modern CLI tools
if command -v batcat >/dev/null 2>&1; then
    alias cat="batcat"
fi

if command -v eza >/dev/null 2>&1; then
    alias ls="eza"
    alias ll="eza -l"
    alias la="eza -la"
fi

# Mise tools alias
alias tools="mise ls --current"

# Debug: Check if starship is available
if [ -n "$DEVCONTAINER_DEBUG" ]; then
    echo "DEBUG: PATH=$PATH"
    echo "DEBUG: Checking for starship..."
    which starship || echo "DEBUG: starship not found in PATH"
fi

# Initialize starship prompt (must be last)
# First try direct path, then command lookup
if [ -x "$HOME/.local/share/mise/installs/starship/latest/bin/starship" ]; then
    eval "$($HOME/.local/share/mise/installs/starship/latest/bin/starship init ${SHELL##*/})"
elif command -v starship >/dev/null 2>&1; then
    eval "$(starship init ${SHELL##*/})"
else
    echo "Warning: starship not found. Please ensure mise tools are installed."
fi
'

# Function to append config to shell file
append_to_shell_config() {
    local shell_file="$1"
    if [ -f "$shell_file" ]; then
        echo "" >> "$shell_file"
        echo "$DEVCONTAINER_CONFIG" >> "$shell_file"
        echo "Updated $(basename "$shell_file") with devcontainer configuration"
    fi
}

# Apply to both shells
append_to_shell_config ~/.zshrc
append_to_shell_config ~/.bashrc

echo "Shell configuration complete."