#!/bin/bash
# Setup shell configurations

set -e

USER=${1:-"zero"}
HOME="/home/$USER"

# Ensure user home directory exists
mkdir -p "$HOME"

# Setup .bashrc with simple prompt
cat > "$HOME/.bashrc" << 'EOF'
# Simple bash configuration

# Set simple prompt
PS1="> "

# Basic aliases
alias ll="ls -la"
alias la="ls -A"
alias l="ls -CF"

# Enable color support for ls
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
fi
EOF

# Setup .zshrc with simple prompt
cat > "$HOME/.zshrc" << 'EOF'
# Simple zsh configuration

# Set simple prompt
PROMPT="> "

# Basic aliases
alias ll="ls -la"
alias la="ls -A"
alias l="ls -CF"

# Enable color support for ls
if [[ -x /usr/bin/dircolors ]]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
fi

# Basic zsh settings
setopt AUTO_CD
setopt HIST_VERIFY
setopt SHARE_HISTORY
setopt EXTENDED_HISTORY

# History settings
HISTFILE=~/.zsh_history
HISTSIZE=1000
SAVEHIST=1000
EOF

# Setup .bash_profile (sourced for login bash shells)
cat > "$HOME/.bash_profile" << 'EOF'
# Bash profile configuration

# Source .bashrc if it exists
if [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi
EOF

# Setup .profile (POSIX shell profile, sourced by various shells)
cat > "$HOME/.profile" << 'EOF'
# POSIX shell profile

# Set PATH
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Source .bashrc if running bash and .bashrc exists
if [ -n "$BASH_VERSION" ] && [ -f "$HOME/.bashrc" ]; then
    source "$HOME/.bashrc"
fi
EOF

# Setup .zshenv (always sourced by zsh - only place we need PATH for zsh)
cat > "$HOME/.zshenv" << 'EOF'
# Zsh environment configuration

# Set PATH
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
EOF

# Setup .zprofile (empty placeholder for login zsh shells)
touch "$HOME/.zprofile"

# Set proper ownership
chown -R "$USER:$USER" "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.bash_profile" "$HOME/.profile" "$HOME/.zshenv" "$HOME/.zprofile"

echo "Shell configurations created for user: $USER"
