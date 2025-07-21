#!/bin/bash
set -e

# ========================================
# STARSHIP INSTALLATION
# ========================================

echo "⭐ Installing Starship prompt..."
curl -sS https://starship.rs/install.sh | sh -s -- -y

# ========================================
# STARSHIP CONFIGURATION
# ========================================

# Function to add starship initialization to shell config files
configure_starship_init() {
    local config_file="$1"
    local shell_name="$2"
    local marker_start="# >>> Starship init - START >>>"
    local marker_end="# <<< Starship init - END <<<"
    
    # Check if already configured
    if [ -f "$config_file" ] && grep -q "$marker_start" "$config_file"; then
        return 0
    fi
    
    # Create file if it doesn't exist
    if [ ! -f "$config_file" ]; then
        touch "$config_file"
    fi
    
    # Add newline if file doesn't end with one
    if [ -s "$config_file" ] && [ "$(tail -c 1 "$config_file")" != "" ]; then
        echo "" >> "$config_file"
    fi
    
    # Append starship initialization
    cat >> "$config_file" << EOF

$marker_start
# Starship - Cross-shell prompt (interactive shells only)
if command -v starship >/dev/null 2>&1 && [[ \$- == *i* ]]; then
    eval "\$(starship init $shell_name)"
fi
$marker_end
EOF
}

# Function to install starship configuration
install_starship_config() {
    local user_home="$1"
    local configs_dir="$2"
    
    mkdir -p "$user_home/.config"
    
    # Check for existing starship config
    if [ -f "$user_home/.config/starship.toml" ]; then
        echo "  Found existing starship.toml, will be replaced"
    fi
    
    # Get the script directory to find starship config
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local starship_config="$script_dir/starship/starship.toml"
    
    if [ -f "$starship_config" ]; then
        cp "$starship_config" "$user_home/.config/starship.toml"
        echo "  Installed starship configuration"
    fi
}

# Get starship init content for template replacement
get_starship_init() {
    local shell_name="$1"
    cat << EOF
# Starship - Cross-shell prompt (interactive shells only)
if command -v starship >/dev/null 2>&1 && [[ \$- == *i* ]]; then
    eval "\$(starship init $shell_name)"
fi
EOF
}