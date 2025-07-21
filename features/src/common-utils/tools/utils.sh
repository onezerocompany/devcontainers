#!/bin/bash
# Centralized tool configuration manager for modern-shell feature
set -e

# Script directory
UTILS_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FEATURE_DIR="$(dirname "$UTILS_SCRIPT_DIR")"
CONFIGS_DIR="${FEATURE_DIR}/configs"

# Configuration markers
MARKER_START="# >>> Modern Shell Tools - START >>>"
MARKER_END="# <<< Modern Shell Tools - END <<<"

# Helper function to check if our config is already added
is_configured() {
    local file=$1
    if [ -f "$file" ] && grep -q "$MARKER_START" "$file"; then
        return 0
    fi
    return 1
}

# Helper function to append our config to a file
append_config() {
    local file=$1
    local content=$2
    
    # Create file if it doesn't exist
    if [ ! -f "$file" ]; then
        touch "$file"
    fi
    
    # Check if already configured
    if is_configured "$file"; then
        echo "  $(basename "$file") already configured, skipping..."
        return
    fi
    
    # Add newline if file doesn't end with one
    if [ -s "$file" ] && [ "$(tail -c 1 "$file")" != "" ]; then
        echo "" >> "$file"
    fi
    
    # Append our configuration with markers
    {
        echo ""
        echo "$MARKER_START"
        echo "# Added by Modern Shell Tools feature"
        echo "# $(date)"
        echo "$content"
        echo "$MARKER_END"
    } >> "$file"
    
    echo "  Updated $(basename "$file")"
}

# Helper function to build shell configuration content from templates
build_shell_config() {
    local template_file=$1
    local shell_type=$2
    local user=$3
    local home_dir=$4
    local install_starship=$5
    local install_zoxide=$6
    local install_eza=$7
    local install_bat=$8
    
    if [ ! -f "$template_file" ]; then
        echo "Warning: Template file $template_file not found"
        return 1
    fi
    
    local temp_file="/tmp/modern_shell_config_$$"
    cp "$template_file" "$temp_file"
    
    # Replace shell placeholder
    sed -i "s/{{SHELL}}/$shell_type/g" "$temp_file"
    
    # Build complete content
    local content=""
    content=$(cat "$temp_file")
    
    # Replace placeholders with actual content
    # Mise aliases (always included since Mise is in the base configuration)
    if [ -f "$CONFIGS_DIR/aliases/mise.sh" ]; then
        local mise_aliases=$(cat "$CONFIGS_DIR/aliases/mise.sh")
        content=$(echo "$content" | sed "s|{{MISE_ALIASES}}|$mise_aliases|g")
    else
        content=$(echo "$content" | sed "s|{{MISE_ALIASES}}||g")
    fi
    
    # Tool-specific configurations
    if [ "$install_eza" = "true" ] && [ -f "$CONFIGS_DIR/aliases/eza.sh" ]; then
        local eza_aliases=$(cat "$CONFIGS_DIR/aliases/eza.sh")
        content=$(echo "$content" | sed "s|{{EZA_ALIASES}}|$eza_aliases|g")
    else
        content=$(echo "$content" | sed "s|{{EZA_ALIASES}}||g")
    fi
    
    if [ "$install_bat" = "true" ] && [ -f "$CONFIGS_DIR/aliases/bat.sh" ]; then
        local bat_aliases=$(cat "$CONFIGS_DIR/aliases/bat.sh")
        content=$(echo "$content" | sed "s|{{BAT_ALIASES}}|$bat_aliases|g")
    else
        content=$(echo "$content" | sed "s|{{BAT_ALIASES}}||g")
    fi
    
    if [ "$install_starship" = "true" ] && [ -f "$CONFIGS_DIR/init/starship.sh" ]; then
        local starship_init=$(cat "$CONFIGS_DIR/init/starship.sh" | sed "s/{{SHELL}}/$shell_type/g")
        content=$(echo "$content" | sed "s|{{STARSHIP_INIT}}|$starship_init|g")
    else
        content=$(echo "$content" | sed "s|{{STARSHIP_INIT}}||g")
    fi
    
    if [ "$install_zoxide" = "true" ] && [ -f "$CONFIGS_DIR/init/zoxide.sh" ]; then
        local zoxide_init=$(cat "$CONFIGS_DIR/init/zoxide.sh" | sed "s/{{SHELL}}/$shell_type/g")
        content=$(echo "$content" | sed "s|{{ZOXIDE_INIT}}|$zoxide_init|g")
    else
        content=$(echo "$content" | sed "s|{{ZOXIDE_INIT}}||g")
    fi
    
    # Add MOTD display
    if [ -f "$CONFIGS_DIR/motd/motd.sh" ]; then
        local motd_display="[ -f ~/.config/modern-shell-motd.sh ] && ~/.config/modern-shell-motd.sh"
        content=$(echo "$content" | sed "s|{{MOTD_DISPLAY}}|$motd_display|g")
    else
        content=$(echo "$content" | sed "s|{{MOTD_DISPLAY}}||g")
    fi
    
    # Clean up any remaining placeholders
    content=$(echo "$content" | grep -v "{{.*}}")
    
    rm -f "$temp_file"
    echo "$content"
}

# Configure shell files for a user
configure_user_shells() {
    local user=$1
    local home_dir=$2
    local install_starship=$3
    local install_zoxide=$4
    local install_eza=$5
    local install_bat=$6
    
    echo "🔧 Configuring shells for $user..."
    
    # Check for existing files
    echo "  Checking for existing shell configurations..."
    [ -f "$home_dir/.bashrc" ] && echo "  Found existing .bashrc"
    [ -f "$home_dir/.bash_profile" ] && echo "  Found existing .bash_profile"
    [ -f "$home_dir/.zshrc" ] && echo "  Found existing .zshrc"
    [ -f "$home_dir/.zshenv" ] && echo "  Found existing .zshenv"
    [ -f "$home_dir/.zprofile" ] && echo "  Found existing .zprofile"
    
    # Configure bash
    if [ -f "$CONFIGS_DIR/bashrc" ]; then
        bashrc_content=$(build_shell_config "$CONFIGS_DIR/bashrc" "bash" "$user" "$home_dir" "$install_starship" "$install_zoxide" "$install_eza" "$install_bat")
        append_config "$home_dir/.bashrc" "$bashrc_content"
    fi
    
    if [ -f "$CONFIGS_DIR/bash_profile" ]; then
        bash_profile_content=$(cat "$CONFIGS_DIR/bash_profile")
        append_config "$home_dir/.bash_profile" "$bash_profile_content"
    fi
    
    # Configure zsh
    if [ -f "$CONFIGS_DIR/zshrc" ]; then
        zshrc_content=$(build_shell_config "$CONFIGS_DIR/zshrc" "zsh" "$user" "$home_dir" "$install_starship" "$install_zoxide" "$install_eza" "$install_bat")
        append_config "$home_dir/.zshrc" "$zshrc_content"
    fi
    
    if [ -f "$CONFIGS_DIR/zshenv" ]; then
        zshenv_content=$(cat "$CONFIGS_DIR/zshenv")
        append_config "$home_dir/.zshenv" "$zshenv_content"
    fi
    
    if [ -f "$CONFIGS_DIR/zprofile" ]; then
        zprofile_content=$(cat "$CONFIGS_DIR/zprofile")
        append_config "$home_dir/.zprofile" "$zprofile_content"
    fi
}

# Install tool-specific configurations
install_tool_configs() {
    local user=$1
    local home_dir=$2
    local install_starship=$3
    local install_zoxide=$4
    local install_eza=$5
    local install_bat=$6
    
    # Copy starship config if installed
    if [ "$install_starship" = "true" ] && [ -f "$CONFIGS_DIR/starship.toml" ]; then
        mkdir -p "$home_dir/.config"
        
        if [ -f "$home_dir/.config/starship.toml" ]; then
            echo "  Found existing starship.toml, will be replaced"
        fi
        
        cp "$CONFIGS_DIR/starship.toml" "$home_dir/.config/starship.toml"
        echo "  Installed starship configuration"
    fi
    
    # Copy MOTD script
    if [ -f "$CONFIGS_DIR/motd/motd.sh" ]; then
        mkdir -p "$home_dir/.config"
        cp "$CONFIGS_DIR/motd/motd.sh" "$home_dir/.config/modern-shell-motd.sh"
        chmod +x "$home_dir/.config/modern-shell-motd.sh"
        echo "  Installed MOTD script"
    fi
}

# Fix ownership of files
fix_ownership() {
    local user=$1
    local home_dir=$2
    
    if [ "$user" != "root" ]; then
        # Fix ownership for all shell configs
        [ -f "$home_dir/.bashrc" ] && chown "$user:$user" "$home_dir/.bashrc"
        [ -f "$home_dir/.bash_profile" ] && chown "$user:$user" "$home_dir/.bash_profile"
        [ -f "$home_dir/.zshrc" ] && chown "$user:$user" "$home_dir/.zshrc"
        [ -f "$home_dir/.zshenv" ] && chown "$user:$user" "$home_dir/.zshenv"
        [ -f "$home_dir/.zprofile" ] && chown "$user:$user" "$home_dir/.zprofile"
        
        # Fix ownership for config directory
        if [ -d "$home_dir/.config" ]; then
            chown -R "$user:$user" "$home_dir/.config"
        fi
    fi
}

# Main configuration function
configure_tools() {
    local user=$1
    local home_dir=$2
    local install_starship=${3:-"false"}
    local install_zoxide=${4:-"false"}
    local install_eza=${5:-"false"}
    local install_bat=${6:-"false"}
    
    echo "🛠️  Configuring modern shell tools for user: $user"
    echo "   Home directory: $home_dir"
    echo "   Starship: $install_starship"
    echo "   Zoxide: $install_zoxide" 
    echo "   Eza: $install_eza"
    echo "   Bat: $install_bat"
    
    # Configure shell files
    configure_user_shells "$user" "$home_dir" "$install_starship" "$install_zoxide" "$install_eza" "$install_bat"
    
    # Install tool-specific configurations
    install_tool_configs "$user" "$home_dir" "$install_starship" "$install_zoxide" "$install_eza" "$install_bat"
    
    # Fix ownership
    fix_ownership "$user" "$home_dir"
    
    echo "✅ Shell configuration completed for $user"
}

# Allow this script to be sourced or called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Called directly - expect arguments
    if [ $# -lt 2 ]; then
        echo "Usage: $0 <user> <home_dir> [install_starship] [install_zoxide] [install_eza] [install_bat]"
        exit 1
    fi
    
    configure_tools "$@"
fi