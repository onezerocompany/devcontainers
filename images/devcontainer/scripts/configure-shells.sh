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

# Display MOTD only in interactive shells with proper terminal
if [[ -o interactive ]] && [[ -t 0 ]] && [[ "$TERM" != "dumb" ]]; then
    if [ -f /etc/motd ]; then cat /etc/motd; fi
fi

# Shell options
setopt auto_cd 2>/dev/null || true  # zsh only

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