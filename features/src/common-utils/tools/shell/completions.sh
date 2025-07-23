#!/bin/bash
set -e

# Source utils functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/utils.sh"

install_completions() {
    local INSTALL_COMPLETIONS=${1:-true}

    if [ "$INSTALL_COMPLETIONS" != "true" ]; then
        echo "  ⚠️  Shell completions installation skipped"
        return 0
    fi

    echo "🔧 Installing shell completions..."

    # Always setup completion directories and completions
    setup_completion_directories
    setup_tool_completions
    setup_completion_loading
}

setup_completion_directories() {
    echo "  🔧 Setting up completion directories..."
    
    local USER_NAME=$(username)
    local USER_HOME=$(user_home)
    
    # Create completion directories
    mkdir -p "${USER_HOME}/.local/share/bash-completion/completions"
    mkdir -p "${USER_HOME}/.local/share/zsh/site-functions"
    
    # Set ownership if not root
    if [ "$USER_NAME" != "root" ]; then
        chown -R "$USER_NAME:$USER_NAME" "${USER_HOME}/.local" 2>/dev/null || true
    fi
    
    echo "  ✓ Completion directories created"
}

setup_tool_completions() {
    echo "  🔧 Setting up tool completions..."
    
    local USER_HOME=$(user_home)
    
    # Setup GitHub CLI completions
    if command -v gh >/dev/null 2>&1; then
        gh completion -s bash > "${USER_HOME}/.local/share/bash-completion/completions/gh" 2>/dev/null || true
        gh completion -s zsh > "${USER_HOME}/.local/share/zsh/site-functions/_gh" 2>/dev/null || true
        echo "    ✓ GitHub CLI completions configured"
    fi
    
    # Setup GitLab CLI completions
    if command -v glab >/dev/null 2>&1; then
        glab completion -s bash > "${USER_HOME}/.local/share/bash-completion/completions/glab" 2>/dev/null || true
        glab completion -s zsh > "${USER_HOME}/.local/share/zsh/site-functions/_glab" 2>/dev/null || true
        echo "    ✓ GitLab CLI completions configured"
    fi
    
    # Setup Docker completions
    if command -v docker >/dev/null 2>&1; then
        docker completion bash > "${USER_HOME}/.local/share/bash-completion/completions/docker" 2>/dev/null || true
        docker completion zsh > "${USER_HOME}/.local/share/zsh/site-functions/_docker" 2>/dev/null || true
        echo "    ✓ Docker completions configured"
    fi
    
    # Setup Docker Compose completions
    if command -v docker-compose >/dev/null 2>&1; then
        docker-compose completion bash > "${USER_HOME}/.local/share/bash-completion/completions/docker-compose" 2>/dev/null || true
        docker-compose completion zsh > "${USER_HOME}/.local/share/zsh/site-functions/_docker-compose" 2>/dev/null || true
        echo "    ✓ Docker Compose completions configured"
    fi
    
    echo "  ✓ Tool completions configured"
}

setup_completion_loading() {
    echo "  🔧 Setting up completion loading..."
    
    # Add completion loading configuration
    add_config "shared" "rc" "$(cat << 'EOF'
# Local shell completions setup
if [ "%SHELL%" = "zsh" ]; then
    # Add local completion directories to fpath for zsh
    fpath=("$HOME/.local/share/zsh/site-functions" $fpath)
else
    # Add local bash completions
    if [ -d "$HOME/.local/share/bash-completion/completions" ]; then
        for completion in "$HOME/.local/share/bash-completion/completions"/*; do
            [ -r "$completion" ] && source "$completion"
        done
    fi
fi
EOF
)"
    
    echo "  ✓ Completion loading configured"
}

# Run installation with environment variables
INSTALL_COMPLETIONS=${COMPLETIONS_INSTALL:-true}

install_completions "$INSTALL_COMPLETIONS"