#!/bin/bash
set -e

# ========================================
# UTILITIES BUNDLE INSTALLATION
# ========================================

install_utilities_bundle() {
    local install_build_tools="${1:-true}"
    local install_github_cli="${2:-true}"
    
    echo "⚡ Installing utilities bundle..."

    # Install core system utilities
    local core_packages="curl wget unzip zip p7zip-full tree less ncdu man-db htop lsof procps strace ca-certificates gnupg lsb-release software-properties-common bash-completion git-extras"
    
    # Add build tools if enabled
    if [ "$install_build_tools" = "true" ]; then
        echo "  Including build tools..."
        core_packages="$core_packages build-essential cmake pkg-config"
    fi
    
    # Add GitHub CLI tools if enabled
    if [ "$install_github_cli" = "true" ]; then
        echo "  Including GitHub CLI tools..."
        core_packages="$core_packages gh"
    fi
    
    # Install packages
    apt-get install -y $core_packages

# Install modern development utilities
echo "📦 Installing modern utilities..."

# Note: lazygit removed as requested

# Install fd (find alternative)
FD_VERSION="8.7.1"
case $ARCH in
    amd64) FD_ARCH="x86_64" ;;
    arm64) FD_ARCH="aarch64" ;;
    *) echo "Unsupported architecture for fd: $ARCH"; return 0 ;;
esac
FD_URL="https://github.com/sharkdp/fd/releases/download/v${FD_VERSION}/fd-v${FD_VERSION}-${FD_ARCH}-unknown-linux-musl.tar.gz"
echo "  Downloading fd from: $FD_URL"
if curl -fsSL "$FD_URL" -o /tmp/fd.tar.gz; then
    tar -xzf /tmp/fd.tar.gz -C /tmp
    mv "/tmp/fd-v${FD_VERSION}-${FD_ARCH}-unknown-linux-musl/fd" /usr/local/bin/
    chmod +x /usr/local/bin/fd
    rm -rf /tmp/fd*
    echo "  ✓ fd installed successfully"
else
    echo "  ⚠️  Failed to download fd, skipping"
    rm -rf /tmp/fd*
fi

# Install ripgrep (grep alternative)
RG_VERSION="14.0.3"
case $ARCH in
    amd64) RG_ARCH="x86_64" ;;
    arm64) RG_ARCH="aarch64" ;;
    *) echo "Unsupported architecture for ripgrep: $ARCH"; return 0 ;;
esac
RG_URL="https://github.com/BurntSushi/ripgrep/releases/download/${RG_VERSION}/ripgrep-${RG_VERSION}-${RG_ARCH}-unknown-linux-musl.tar.gz"
echo "  Downloading ripgrep from: $RG_URL"
if curl -fsSL "$RG_URL" -o /tmp/ripgrep.tar.gz; then
    tar -xzf /tmp/ripgrep.tar.gz -C /tmp
    mv "/tmp/ripgrep-${RG_VERSION}-${RG_ARCH}-unknown-linux-musl/rg" /usr/local/bin/
    chmod +x /usr/local/bin/rg
    rm -rf /tmp/ripgrep*
    echo "  ✓ ripgrep installed successfully"
else
    echo "  ⚠️  Failed to download ripgrep, skipping"
    rm -rf /tmp/ripgrep*
fi

    echo "✓ Utilities bundle installed"
}

# ========================================
# UTILITIES BUNDLE CONFIGURATION
# ========================================

# Function to setup utilities for a user
setup_utilities_for_user() {
    local user_home="$1"
    local username="$2"

    echo "  Setting up utilities for $username..."

    # Create directories
    mkdir -p "$user_home/.config"
    mkdir -p "$user_home/.local/share/bash-completion/completions"
    mkdir -p "$user_home/.local/share/zsh/site-functions"

    # Setup git config if it doesn't exist
    if [ ! -f "$user_home/.gitconfig" ]; then
        cat > "$user_home/.gitconfig" << 'EOF'
[init]
    defaultBranch = main
[pull]
    rebase = false
[push]
    default = simple
[core]
    editor = code --wait
    autocrlf = input
[alias]
    co = checkout
    br = branch
    ci = commit
    st = status
    unstage = reset HEAD --
    last = log -1 HEAD
    visual = !gitk
    lg = log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit
EOF
    fi

    # Setup completions for CLI tools
    if command -v gh >/dev/null 2>&1; then
        gh completion -s bash > "$user_home/.local/share/bash-completion/completions/gh" 2>/dev/null || true
        gh completion -s zsh > "$user_home/.local/share/zsh/site-functions/_gh" 2>/dev/null || true
    fi

    # Note: glab completions removed (tool not installed)

    # Enable bash completion globally
    if ! grep -q "/etc/bash_completion" /etc/bash.bashrc 2>/dev/null; then
        echo "# Enable bash completion" >> /etc/bash.bashrc
        echo "if [ -f /etc/bash_completion ] && ! shopt -oq posix; then" >> /etc/bash.bashrc
        echo "    . /etc/bash_completion" >> /etc/bash.bashrc
        echo "fi" >> /etc/bash.bashrc
    fi

    # Set proper ownership
    if [ "$username" != "root" ]; then
        chown -R "$username:$username" "$user_home/.config" 2>/dev/null || true
        chown -R "$username:$username" "$user_home/.local" 2>/dev/null || true
        chown "$username:$username" "$user_home/.gitconfig" 2>/dev/null || true
    fi

    echo "    ✓ Utilities configured for $username"
}

# Get utilities aliases for shell configuration
get_utilities_aliases() {
    cat << 'EOF'
# Utility aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'
alias -- -='cd -'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias psg='ps aux | grep'
alias h='history'
alias hg='history | grep'
alias myip='curl -s ipinfo.io/ip'
alias weather='curl -s wttr.in'
# lg alias removed (lazygit not installed)
alias find='fd'
alias search='rg'
# tldr alias removed (tlrc tool not installed)
EOF
}
