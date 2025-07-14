#!/bin/bash
set -e

echo "Configuring shells for devcontainer..."

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

# Append to .zshrc if it exists
if [ -f ~/.zshrc ]; then
    echo "" >> ~/.zshrc
    echo "$DEVCONTAINER_CONFIG" >> ~/.zshrc
    echo "Updated .zshrc with devcontainer configuration"
fi

# Append to .bashrc if it exists
if [ -f ~/.bashrc ]; then
    echo "" >> ~/.bashrc
    echo "$DEVCONTAINER_CONFIG" >> ~/.bashrc
    echo "Updated .bashrc with devcontainer configuration"
fi

echo "Shell configuration complete."