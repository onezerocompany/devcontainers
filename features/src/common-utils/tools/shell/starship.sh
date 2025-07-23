#!/bin/bash
set -e

# Source utils functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/utils.sh"

install_starship() {
    local INSTALL_STARSHIP=${1:-true}

    if [ "$INSTALL_STARSHIP" != "true" ]; then
        echo "  ⚠️  Starship installation skipped"
        return 0
    fi

    echo "⭐ Installing Starship prompt..."

    # Download and run starship installer with enhanced validation
    local STARSHIP_INSTALL_URL="https://starship.rs/install.sh"
    local temp_installer="/tmp/starship-install.sh"
    
    echo "  📥 Downloading starship installer from: $STARSHIP_INSTALL_URL"
    
    if secure_download "$STARSHIP_INSTALL_URL" "$temp_installer"; then
        # Enhanced validation of downloaded script
        if [ -s "$temp_installer" ] && head -1 "$temp_installer" | grep -q '^#!/'; then
            # Additional validation: check for suspicious patterns
            if grep -q -E "(curl|wget).*\|.*sh|eval.*\$\(" "$temp_installer"; then
                echo "  ⚠️  Warning: Installer contains potentially risky patterns"
                echo "  📝 Please review the installer script before proceeding"
            fi
            
            # Verify it's actually the starship installer
            if grep -q "starship" "$temp_installer" && grep -q "github.com/starship/starship" "$temp_installer"; then
                chmod +x "$temp_installer"
                "$temp_installer" -y
                echo "  ✓ starship installed successfully"
            else
                echo "  ⚠️  Downloaded file doesn't appear to be the starship installer"
                rm -f "$temp_installer"
                return 1
            fi
        else
            echo "  ⚠️  Downloaded file is not a valid shell script"
            rm -f "$temp_installer"
            return 1
        fi
        rm -f "$temp_installer"
    else
        echo "  ⚠️  Failed to download starship installer"
        return 1
    fi

    # Always setup configuration and initialization
    setup_starship_config
    setup_starship_init
}

setup_starship_config() {
    echo "  🔧 Setting up Starship configuration..."
    
    local USER_NAME=$(username)
    local USER_HOME=$(user_home)
    
    # Create starship config directory
    local STARSHIP_CONFIG_DIR="${USER_HOME}/.config"
    mkdir -p "$STARSHIP_CONFIG_DIR"
    
    # Create starship configuration
    cat > "${STARSHIP_CONFIG_DIR}/starship.toml" << 'EOF'
add_newline = true
format = "[](fg:purple)[dev ](bg:purple fg:white)$username "
right_format = "$directory"

[directory]
disabled = false
before_repo_root_style = "fg:white"
format = "[](fg:white)[$path](bg:white fg:black)[](fg:white)"
read_only = ""
repo_root_format = "[](fg:purple)[ $repo_root](bg:purple fg:white)[](fg:purple bg:white)[ .$path ](bg:white fg:black)[](fg:white)"
repo_root_style = "fg:white"
truncation_length = 3

[username]
format = "[  $user ]($style)[](fg:white)"
show_always = true
style_root = "bg:white fg:black bold"
style_user = "bg:white fg:black"
EOF

    # Set ownership if not root
    if [ "$USER_NAME" != "root" ]; then
        chown -R "$USER_NAME:$USER_NAME" "$STARSHIP_CONFIG_DIR"
    fi
    
    echo "  ✓ Starship configuration created at ${STARSHIP_CONFIG_DIR}/starship.toml"
}

setup_starship_init() {
    echo "  🔧 Setting up Starship initialization..."
    
    # Add starship initialization for interactive shells only
    add_config "shared" "rc" "$(cat << 'EOF'
# Starship - Cross-shell prompt (interactive shells only)
if command -v starship >/dev/null 2>&1 && [[ $- == *i* ]]; then
    eval "$(starship init %SHELL%)"
fi
EOF
)"
    
    echo "  ✓ Starship initialization configured"
}

# Check if starship should be installed (individual option or shell bundle)
if should_install_tool "STARSHIP" "SHELLBUNDLE"; then
    # Run installation
    install_starship "true"
else
    echo "  ⏭️  Skipping starship installation (disabled)"
fi