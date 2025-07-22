#!/bin/bash
set -e

# ========================================
# SHELL COMPLETIONS SETUP
# ========================================

echo "🔧 Setting up shell completions..."

# Function to setup completions for a user
setup_completions_for_user() {
    local user_home="$1"
    local username="$2"
    
    echo "  Setting up completions for $username..."
    
    # Create completion directories
    mkdir -p "$user_home/.local/share/bash-completion/completions"
    mkdir -p "$user_home/.local/share/zsh/site-functions"
    
    # Setup GitHub CLI completions
    if command -v gh >/dev/null 2>&1; then
        gh completion -s bash > "$user_home/.local/share/bash-completion/completions/gh" 2>/dev/null || true
        gh completion -s zsh > "$user_home/.local/share/zsh/site-functions/_gh" 2>/dev/null || true
    fi
    
    # Setup GitLab CLI completions
    if command -v glab >/dev/null 2>&1; then
        glab completion -s bash > "$user_home/.local/share/bash-completion/completions/glab" 2>/dev/null || true
        glab completion -s zsh > "$user_home/.local/share/zsh/site-functions/_glab" 2>/dev/null || true
    fi
    
    # Setup Docker completions
    if command -v docker >/dev/null 2>&1; then
        docker completion bash > "$user_home/.local/share/bash-completion/completions/docker" 2>/dev/null || true
        docker completion zsh > "$user_home/.local/share/zsh/site-functions/_docker" 2>/dev/null || true
    fi
    
    # Setup Docker Compose completions
    if command -v docker-compose >/dev/null 2>&1; then
        docker-compose completion bash > "$user_home/.local/share/bash-completion/completions/docker-compose" 2>/dev/null || true
        docker-compose completion zsh > "$user_home/.local/share/zsh/site-functions/_docker-compose" 2>/dev/null || true
    fi
    
    # Add completion configurations to temporary files
    
    # Define temporary file paths (consistent with utils.sh)
    local TMP_BASHRC="/tmp/tmp_bashrc"
    local TMP_ZSHRC="/tmp/tmp_zshrc"
    
    # Zsh completion configuration
    local zsh_completion_content=$(cat << 'EOF'
# Add local completion directories to fpath
fpath=($HOME/.local/share/zsh/site-functions $fpath)
EOF
)
    
    # Bash completion configuration
    local bash_completion_content=$(cat << 'EOF'
# Add local bash completions
if [ -d "$HOME/.local/share/bash-completion/completions" ]; then
    for completion in "$HOME/.local/share/bash-completion/completions"/*; do
        [ -r "$completion" ] && source "$completion"
    done
fi
EOF
)
    
    # Add to temporary files
    echo "" >> "$TMP_ZSHRC"
    echo "$zsh_completion_content" >> "$TMP_ZSHRC"
    echo "" >> "$TMP_ZSHRC"
    
    echo "" >> "$TMP_BASHRC"
    echo "$bash_completion_content" >> "$TMP_BASHRC"
    echo "" >> "$TMP_BASHRC"
    
    # Set proper ownership
    if [ "$username" != "root" ]; then
        chown -R "$username:$username" "$user_home/.local" 2>/dev/null || true
    fi
    
    echo "    ✓ Completions configured for $username"
}

# Get completions setup content for template replacement
get_completions_setup() {
    cat << 'EOF'
# Custom completions setup
fpath=($HOME/.local/share/zsh/site-functions $fpath)
if [ -d "$HOME/.local/share/bash-completion/completions" ]; then
    for completion in "$HOME/.local/share/bash-completion/completions"/*; do
        [ -r "$completion" ] && source "$completion"
    done
fi
EOF
}

echo "✓ Shell completions setup completed"