#!/bin/bash
# Common Utilities Feature Installation Script

# Feature options (using correct environment variable names from devcontainer-feature.json)
DEFAULT_SHELL="${DEFAULTSHELL:-zsh}"
INSTALL_ZSH="${ZSH:-true}"

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Ensure non-interactive mode for apt
export DEBIAN_FRONTEND=noninteractive

# Source utility functions
source "${SCRIPT_DIR}/lib/utils.sh"

echo "🔧 Starting Common Utilities installation..."


# Install and configure shell
install_and_configure_shell() {
    echo "🐚 Setting up shell environment..."
    
    local user_name=$(username)
    local user_home=$(user_home)
    
    # Install zsh if requested
    if [ "$INSTALL_ZSH" = "true" ]; then
        echo "  📦 Installing zsh shell..."
        if is_debian_based; then
            apt_get_update_if_needed
            apt-get install -y zsh
        fi
        echo "  ✅ Zsh installed"
    else
        echo "  ⏭️  Skipping zsh installation (disabled)"
    fi
    
    # Set user's default shell
    if [ "$DEFAULT_SHELL" = "zsh" ] && [ "$INSTALL_ZSH" = "true" ]; then
        echo "  🔧 Setting zsh as default shell for $user_name..."
        if command -v zsh >/dev/null 2>&1; then
            # Set shell for non-root user
            if [ "$user_name" != "root" ]; then
                chsh -s "$(which zsh)" "$user_name" 2>/dev/null || true
            fi
            # Set shell for root user
            chsh -s "$(which zsh)" root 2>/dev/null || true
            echo "  ✅ Default shell set to zsh"
        else
            echo "  ⚠️  Zsh not found, keeping current shell"
        fi
    elif [ "$DEFAULT_SHELL" = "bash" ]; then
        echo "  🔧 Setting bash as default shell for $user_name..."
        if command -v bash >/dev/null 2>&1; then
            # Set shell for non-root user  
            if [ "$user_name" != "root" ]; then
                chsh -s "$(which bash)" "$user_name" 2>/dev/null || true
            fi
            # Set shell for root user
            chsh -s "$(which bash)" root 2>/dev/null || true
            echo "  ✅ Default shell set to bash"
        else
            echo "  ⚠️  Bash not found, keeping current shell"
        fi
    fi
    
    echo "🐚 Shell setup completed"
}

# Install and configure shell first
install_and_configure_shell

# Install all tools - each script will check its own environment variable
find "${SCRIPT_DIR}/tools" -name "*.sh" -type f | sort | while read -r tool_script; do
    echo "  🔧 Running $(basename "$tool_script")..."
    source "$tool_script"
done

# Install all collected packages at once
if is_debian_based; then
    apt_get_update_if_needed
    install_all_pkgs
fi

# Generate shell configuration files from collected configs
generate_config

echo "✅ Common Utilities installation completed!"