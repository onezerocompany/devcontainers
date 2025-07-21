#!/bin/bash
# Shell Configuration Script for Common Utilities Feature
set -e

# Parameters
USERNAME="$1"
USER_HOME="$2"
INSTALL_STARSHIP="$3"
INSTALL_ZOXIDE="$4"
INSTALL_EZA="$5"
INSTALL_BAT="$6"

# Validate parameters
if [ -z "$USERNAME" ] || [ -z "$USER_HOME" ]; then
    echo "Error: Missing required parameters"
    echo "Usage: configure-shells.sh USERNAME USER_HOME INSTALL_STARSHIP INSTALL_ZOXIDE INSTALL_EZA INSTALL_BAT"
    exit 1
fi

echo "🐚 Configuring shells for user: $USERNAME"

# Get the script directory to source tool scripts
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_DIR="$(dirname "$SCRIPT_DIR")/tools"

# Source tool configuration functions
[ -f "$TOOLS_DIR/shell/starship/starship.sh" ] && source "$TOOLS_DIR/shell/starship/starship.sh"
[ -f "$TOOLS_DIR/shell/zoxide.sh" ] && source "$TOOLS_DIR/shell/zoxide.sh"
[ -f "$TOOLS_DIR/shell/eza.sh" ] && source "$TOOLS_DIR/shell/eza.sh"
[ -f "$TOOLS_DIR/shell/bat.sh" ] && source "$TOOLS_DIR/shell/bat.sh"

# Configure zsh
ZSH_CONFIG="$USER_HOME/.zshrc"
if [ "$INSTALL_STARSHIP" = "true" ] && command -v configure_starship_init >/dev/null 2>&1; then
    configure_starship_init "$ZSH_CONFIG" "zsh"
fi

if [ "$INSTALL_ZOXIDE" = "true" ] && command -v configure_zoxide_init >/dev/null 2>&1; then
    configure_zoxide_init "$ZSH_CONFIG" "zsh"
fi

if [ "$INSTALL_EZA" = "true" ] && command -v configure_eza_aliases >/dev/null 2>&1; then
    configure_eza_aliases "$ZSH_CONFIG"
fi

if [ "$INSTALL_BAT" = "true" ] && command -v configure_bat_aliases >/dev/null 2>&1; then
    configure_bat_aliases "$ZSH_CONFIG"
fi

# Configure bash
BASH_CONFIG="$USER_HOME/.bashrc"
if [ "$INSTALL_STARSHIP" = "true" ] && command -v configure_starship_init >/dev/null 2>&1; then
    configure_starship_init "$BASH_CONFIG" "bash"
fi

if [ "$INSTALL_ZOXIDE" = "true" ] && command -v configure_zoxide_init >/dev/null 2>&1; then
    configure_zoxide_init "$BASH_CONFIG" "bash"
fi

if [ "$INSTALL_EZA" = "true" ] && command -v configure_eza_aliases >/dev/null 2>&1; then
    configure_eza_aliases "$BASH_CONFIG"
fi

if [ "$INSTALL_BAT" = "true" ] && command -v configure_bat_aliases >/dev/null 2>&1; then
    configure_bat_aliases "$BASH_CONFIG"
fi

# Install configurations if functions exist
if [ "$INSTALL_STARSHIP" = "true" ] && command -v install_starship_config >/dev/null 2>&1; then
    install_starship_config "$USER_HOME" "$TOOLS_DIR"
fi

# Set ownership if not root
if [ "$USERNAME" != "root" ] && [ -d "$USER_HOME" ]; then
    chown -R "$USERNAME:$USERNAME" "$USER_HOME/.bashrc" "$USER_HOME/.zshrc" "$USER_HOME/.config" 2>/dev/null || true
fi

echo "  ✓ Shell configuration completed for $USERNAME"