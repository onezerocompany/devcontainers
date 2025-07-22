#!/bin/bash
set -e

# ========================================
# EZA INSTALLATION
# ========================================

echo "📋 Installing eza (modern ls)..."
EZA_KEY_URL="https://raw.githubusercontent.com/eza-community/eza/main/deb.asc"
echo "  Downloading eza GPG key from: $EZA_KEY_URL"
if curl -fsSL "$EZA_KEY_URL" -o /tmp/eza.asc; then
    if [ -s /tmp/eza.asc ] && grep -q "BEGIN PGP PUBLIC KEY BLOCK" /tmp/eza.asc; then
        mkdir -p /etc/apt/keyrings
        gpg --dearmor < /tmp/eza.asc > /etc/apt/keyrings/gierens.gpg
        echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | tee /etc/apt/sources.list.d/gierens.list
        chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
        if apt-get update && apt-get install -y eza; then
            echo "  ✓ eza installed successfully from repository"
        else
            echo "  ⚠️  Failed to install eza from repository, cleaning up"
            rm -f /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
        fi
    else
        echo "  ⚠️  Downloaded file is not a valid GPG key, skipping eza installation"
    fi
    rm -f /tmp/eza.asc
else
    echo "  ⚠️  Failed to download eza GPG key, skipping"
    rm -f /tmp/eza.asc
fi

# ========================================
# EZA CONFIGURATION
# ========================================

# Function to add eza aliases to shell config files
configure_eza_aliases() {
    local config_file="$1"
    local marker_start="# >>> Eza aliases - START >>>"
    local marker_end="# <<< Eza aliases - END <<<"
    
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
    
    # Append eza aliases
    cat >> "$config_file" << EOF

$marker_start
# Eza aliases (modern ls)
alias ls='eza'
alias ll='eza -l'
alias la='eza -la'
alias lt='eza --tree'
alias tree='eza --tree'
$marker_end
EOF
}

# Get aliases content for template replacement
get_eza_aliases() {
    cat << 'EOF'
# Eza aliases (modern ls)
alias ls='eza'
alias ll='eza -l'
alias la='eza -la'
alias lt='eza --tree'
alias tree='eza --tree'
EOF
}