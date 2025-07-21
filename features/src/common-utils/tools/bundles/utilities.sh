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
    local core_packages="curl wget unzip zip p7zip-full tree less ncdu man-db htop lsof procps strace ca-certificates gnupg lsb-release software-properties-common bash-completion git-extras tlrc"
    
    # Add build tools if enabled
    if [ "$install_build_tools" = "true" ]; then
        echo "  Including build tools..."
        core_packages="$core_packages build-essential cmake pkg-config"
    fi
    
    # Add GitHub CLI tools if enabled
    if [ "$install_github_cli" = "true" ]; then
        echo "  Including GitHub CLI tools..."
        core_packages="$core_packages gh glab"
    fi
    
    # Install packages
    apt-get install -y $core_packages

# Install modern development utilities
echo "📦 Installing modern utilities..."

# Install lazygit
LAZYGIT_VERSION="0.40.2"
ARCH=$(dpkg --print-architecture)
case $ARCH in
    amd64) LAZYGIT_ARCH="x86_64" ;;
    arm64) LAZYGIT_ARCH="arm64" ;;
    *) echo "Unsupported architecture for lazygit: $ARCH"; return 0 ;;
esac
curl -L "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_${LAZYGIT_ARCH}.tar.gz" -o /tmp/lazygit.tar.gz
tar -xzf /tmp/lazygit.tar.gz -C /tmp
mv /tmp/lazygit /usr/local/bin/
chmod +x /usr/local/bin/lazygit
rm -f /tmp/lazygit.tar.gz

# Install fd (find alternative)
FD_VERSION="8.7.1"
case $ARCH in
    amd64) FD_ARCH="x86_64" ;;
    arm64) FD_ARCH="aarch64" ;;
    *) echo "Unsupported architecture for fd: $ARCH"; return 0 ;;
esac
curl -L "https://github.com/sharkdp/fd/releases/download/v${FD_VERSION}/fd-v${FD_VERSION}-${FD_ARCH}-unknown-linux-musl.tar.gz" -o /tmp/fd.tar.gz
tar -xzf /tmp/fd.tar.gz -C /tmp
mv "/tmp/fd-v${FD_VERSION}-${FD_ARCH}-unknown-linux-musl/fd" /usr/local/bin/
chmod +x /usr/local/bin/fd
rm -rf /tmp/fd*

# Install ripgrep (grep alternative)
RG_VERSION="14.0.3"
case $ARCH in
    amd64) RG_ARCH="x86_64" ;;
    arm64) RG_ARCH="aarch64" ;;
    *) echo "Unsupported architecture for ripgrep: $ARCH"; return 0 ;;
esac
curl -L "https://github.com/BurntSushi/ripgrep/releases/download/${RG_VERSION}/ripgrep-${RG_VERSION}-${RG_ARCH}-unknown-linux-musl.tar.gz" -o /tmp/ripgrep.tar.gz
tar -xzf /tmp/ripgrep.tar.gz -C /tmp
mv "/tmp/ripgrep-${RG_VERSION}-${RG_ARCH}-unknown-linux-musl/rg" /usr/local/bin/
chmod +x /usr/local/bin/rg
rm -rf /tmp/ripgrep*

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

    if command -v glab >/dev/null 2>&1; then
        glab completion -s bash > "$user_home/.local/share/bash-completion/completions/glab" 2>/dev/null || true
        glab completion -s zsh > "$user_home/.local/share/zsh/site-functions/_glab" 2>/dev/null || true
    fi

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
alias lg='lazygit'
alias find='fd'
alias search='rg'
alias tldr='tlrc'
EOF
}
