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

# Function to add eza aliases to temporary config files
configure_eza_aliases() {
    # Define temporary file paths (consistent with utils.sh)
    local TMP_BASHRC="/tmp/tmp_bashrc"
    local TMP_ZSHRC="/tmp/tmp_zshrc"
    
    # Define eza aliases content
    local eza_content=$(cat << 'EOF'
# Eza aliases (modern ls)
alias ls='eza'
alias ll='eza -l'
alias la='eza -la'
alias lt='eza --tree'
alias tree='eza --tree'
EOF
)
    
    # Append to both bash and zsh tmp files
    echo "" >> "$TMP_BASHRC"
    echo "$eza_content" >> "$TMP_BASHRC"
    echo "" >> "$TMP_BASHRC"
    
    echo "" >> "$TMP_ZSHRC"
    echo "$eza_content" >> "$TMP_ZSHRC"
    echo "" >> "$TMP_ZSHRC"
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

# Configure eza aliases when script runs
if command -v eza >/dev/null 2>&1; then
    echo "  Writing eza aliases to temporary files..."
    configure_eza_aliases
fi