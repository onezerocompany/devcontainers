#!/bin/bash
set -e

echo "Configuring shells for devcontainer..."

# Check if configuration already exists to avoid duplicates
if grep -q "DevContainer specific configuration" ~/.zshrc 2>/dev/null || 
   grep -q "DevContainer specific configuration" ~/.bashrc 2>/dev/null; then
    echo "Shell configuration already applied."
    exit 0
fi

# DevContainer-specific configuration that will be appended to existing shell configs
DEVCONTAINER_CONFIG='
# DevContainer specific configuration
# Display MOTD only in interactive shells with proper terminal
if [[ -o interactive ]] && [[ -t 0 ]] && [[ "$TERM" != "dumb" ]]; then
    if [ -f /etc/motd ]; then cat /etc/motd; fi
fi

# Shell options
setopt auto_cd 2>/dev/null || true  # zsh only

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

# Ensure mise tools are in PATH for non-login shells
if [[ ! "$PATH" =~ "$HOME/.local/bin" ]]; then
    if [ -f ~/.zshenv ]; then
        source ~/.zshenv
    elif [ -f ~/.bashrc ]; then
        source ~/.bashrc
    fi
fi

# Initialize starship prompt (must be last)
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init ${SHELL##*/})"
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