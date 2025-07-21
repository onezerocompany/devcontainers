#!/bin/bash
set -e

# Arguments
USER=$1
HOME_DIR=$2
INSTALL_STARSHIP=$3
INSTALL_ZOXIDE=$4
INSTALL_EZA=$5
INSTALL_BAT=$6

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIGS_DIR="${SCRIPT_DIR}/../configs"

echo "🔧 Configuring shells for $USER..."

# Markers for our additions
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

# Helper function to check if file exists (for logging)
check_file() {
    local file=$1
    if [ -f "$file" ]; then
        echo "  Found existing $(basename "$file")"
    fi
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

# Helper function to build content from templates
build_content() {
    local template=$1
    local shell=$2
    local temp_file="/tmp/modern_shell_config_$$"
    
    # Copy template to temp file
    cp "$template" "$temp_file"
    
    # Replace shell placeholder
    sed -i "s/{{SHELL}}/$shell/g" "$temp_file"
    
    # Build complete content
    local content=""
    
    # Add base content
    content=$(cat "$temp_file")
    
    # Replace placeholders with actual content
    # Mise aliases (always included since Mise is in the base configuration)
    if [ -f "$CONFIGS_DIR/aliases/mise.sh" ]; then
        local mise_aliases=$(cat "$CONFIGS_DIR/aliases/mise.sh")
        content=$(echo "$content" | sed "s|{{MISE_ALIASES}}|$mise_aliases|g")
    else
        content=$(echo "$content" | sed "s|{{MISE_ALIASES}}||g")
    fi
    
    if [ "$INSTALL_EZA" = "true" ] && [ -f "$CONFIGS_DIR/aliases/eza.sh" ]; then
        local eza_aliases=$(cat "$CONFIGS_DIR/aliases/eza.sh")
        content=$(echo "$content" | sed "s|{{EZA_ALIASES}}|$eza_aliases|g")
    else
        content=$(echo "$content" | sed "s|{{EZA_ALIASES}}||g")
    fi
    
    if [ "$INSTALL_BAT" = "true" ] && [ -f "$CONFIGS_DIR/aliases/bat.sh" ]; then
        local bat_aliases=$(cat "$CONFIGS_DIR/aliases/bat.sh")
        content=$(echo "$content" | sed "s|{{BAT_ALIASES}}|$bat_aliases|g")
    else
        content=$(echo "$content" | sed "s|{{BAT_ALIASES}}||g")
    fi
    
    if [ "$INSTALL_STARSHIP" = "true" ] && [ -f "$CONFIGS_DIR/init/starship.sh" ]; then
        local starship_init=$(cat "$CONFIGS_DIR/init/starship.sh" | sed "s/{{SHELL}}/$shell/g")
        content=$(echo "$content" | sed "s|{{STARSHIP_INIT}}|$starship_init|g")
    else
        content=$(echo "$content" | sed "s|{{STARSHIP_INIT}}||g")
    fi
    
    if [ "$INSTALL_ZOXIDE" = "true" ] && [ -f "$CONFIGS_DIR/init/zoxide.sh" ]; then
        local zoxide_init=$(cat "$CONFIGS_DIR/init/zoxide.sh" | sed "s/{{SHELL}}/$shell/g")
        content=$(echo "$content" | sed "s|{{ZOXIDE_INIT}}|$zoxide_init|g")
    else
        content=$(echo "$content" | sed "s|{{ZOXIDE_INIT}}||g")
    fi
    
    # Add MOTD display
    if [ -f "$CONFIGS_DIR/motd/motd.sh" ]; then
        local motd_display="[ -f ~/.config/modern-shell-motd.sh ] && ~/.config/modern-shell-motd.sh"
        content=$(echo "$content" | sed "s|{{MOTD_DISPLAY}}|$motd_display|g")
    fi
    
    # Clean up placeholders that weren't replaced
    content=$(echo "$content" | grep -v "{{.*}}")
    
    rm -f "$temp_file"
    echo "$content"
}

# Check for existing files
echo "  Checking for existing shell configurations..."
check_file "$HOME_DIR/.bashrc"
check_file "$HOME_DIR/.bash_profile"
check_file "$HOME_DIR/.zshrc"
check_file "$HOME_DIR/.zshenv"
check_file "$HOME_DIR/.zprofile"

# Configure bash
if [ -f "$CONFIGS_DIR/bashrc" ]; then
    bashrc_content=$(build_content "$CONFIGS_DIR/bashrc" "bash")
    append_config "$HOME_DIR/.bashrc" "$bashrc_content"
fi

if [ -f "$CONFIGS_DIR/bash_profile" ]; then
    bash_profile_content=$(cat "$CONFIGS_DIR/bash_profile")
    append_config "$HOME_DIR/.bash_profile" "$bash_profile_content"
fi

# Configure zsh
if [ -f "$CONFIGS_DIR/zshrc" ]; then
    zshrc_content=$(build_content "$CONFIGS_DIR/zshrc" "zsh")
    append_config "$HOME_DIR/.zshrc" "$zshrc_content"
fi

if [ -f "$CONFIGS_DIR/zshenv" ]; then
    zshenv_content=$(cat "$CONFIGS_DIR/zshenv")
    append_config "$HOME_DIR/.zshenv" "$zshenv_content"
fi

if [ -f "$CONFIGS_DIR/zprofile" ]; then
    zprofile_content=$(cat "$CONFIGS_DIR/zprofile")
    append_config "$HOME_DIR/.zprofile" "$zprofile_content"
fi

# Copy starship config if installed (don't append, use our config)
if [ "$INSTALL_STARSHIP" = "true" ] && [ -f "$CONFIGS_DIR/starship.toml" ]; then
    mkdir -p "$HOME_DIR/.config"
    
    # Check for existing starship config
    if [ -f "$HOME_DIR/.config/starship.toml" ]; then
        echo "  Found existing starship.toml, will be replaced"
    fi
    
    cp "$CONFIGS_DIR/starship.toml" "$HOME_DIR/.config/starship.toml"
    echo "  Installed starship configuration"
fi

# Copy MOTD script
if [ -f "$CONFIGS_DIR/motd/motd.sh" ]; then
    mkdir -p "$HOME_DIR/.config"
    cp "$CONFIGS_DIR/motd/motd.sh" "$HOME_DIR/.config/modern-shell-motd.sh"
    chmod +x "$HOME_DIR/.config/modern-shell-motd.sh"
    echo "  Installed MOTD script"
fi

# Set proper ownership
if [ "$USER" != "root" ]; then
    # Fix ownership for all shell configs
    [ -f "$HOME_DIR/.bashrc" ] && chown "$USER:$USER" "$HOME_DIR/.bashrc"
    [ -f "$HOME_DIR/.bash_profile" ] && chown "$USER:$USER" "$HOME_DIR/.bash_profile"
    [ -f "$HOME_DIR/.zshrc" ] && chown "$USER:$USER" "$HOME_DIR/.zshrc"
    [ -f "$HOME_DIR/.zshenv" ] && chown "$USER:$USER" "$HOME_DIR/.zshenv"
    [ -f "$HOME_DIR/.zprofile" ] && chown "$USER:$USER" "$HOME_DIR/.zprofile"
    
    # Fix ownership for config directory
    if [ -d "$HOME_DIR/.config" ]; then
        chown -R "$USER:$USER" "$HOME_DIR/.config"
    fi
    
fi