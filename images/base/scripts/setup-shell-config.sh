#!/bin/bash
set -e

# Script to set up shell configurations for both bash and zsh
# Expects USERNAME to be passed as first argument
USERNAME=$1

if [ -z "$USERNAME" ]; then
    echo "Error: USERNAME not provided"
    exit 1
fi

USER_HOME="/home/$USERNAME"

# Change default shell to zsh for root and user
chsh -s /bin/zsh
chsh -s /bin/zsh $USERNAME

# Common configuration snippets
setup_path() {
    echo 'export PATH="$HOME/.local/bin:$PATH"'
}

setup_aliases() {
    echo "alias apt-get='apt-fast'"
}

setup_mise_activation() {
    local shell=$1
    local flags=$2
    cat << EOF
if [ -f "\$HOME/.local/bin/mise" ]; then
    eval "\$(\$HOME/.local/bin/mise activate $shell$flags)"
fi
EOF
}

# Create zsh configuration files
create_zsh_configs() {
    # .zshrc - Interactive shell configuration
    cat > "$USER_HOME/.zshrc" << EOF
# Ensure mise tools are available in all contexts
# Source .zshenv to get PATH setup if not already done
if [[ ! "\$PATH" =~ "\$HOME/.local/bin" ]]; then
    source ~/.zshenv
fi

# Zsh completion system
autoload -Uz compinit
compinit

# Basic aliases
$(setup_aliases)

# Mise activation (tool management)
$(setup_mise_activation "zsh" "")
EOF

    # .zshenv - Non-interactive shell configuration
    cat > "$USER_HOME/.zshenv" << EOF
# Path configuration for non-interactive shells
$(setup_path)

# Source mise env for non-interactive shells
$(setup_mise_activation "zsh" " --shims")
EOF

    # .zprofile - Login shell configuration
    cat > "$USER_HOME/.zprofile" << EOF
# Path configuration for login shells
$(setup_path)

# Source mise env for login shells
$(setup_mise_activation "zsh" " --shims")
EOF
}

# Create bash configuration files
create_bash_configs() {
    # .bashrc - Interactive bash shell configuration
    cat > "$USER_HOME/.bashrc" << EOF
# Path configuration
$(setup_path)

# Basic aliases
$(setup_aliases)

# Mise activation (tool management)
$(setup_mise_activation "bash" "")
EOF

    # .bash_profile - Login bash shell configuration
    cat > "$USER_HOME/.bash_profile" << EOF
# Path configuration for login shells
$(setup_path)

# Source .bashrc if it exists
if [ -f "\$HOME/.bashrc" ]; then
    source "\$HOME/.bashrc"
fi

# Source mise env for login shells
$(setup_mise_activation "bash" " --shims")
EOF
}

# Create configurations
create_zsh_configs
create_bash_configs

# Set ownership for all shell configuration files
chown -R $USERNAME:$USERNAME "$USER_HOME/.zshrc" \
    "$USER_HOME/.zshenv" \
    "$USER_HOME/.zprofile" \
    "$USER_HOME/.bashrc" \
    "$USER_HOME/.bash_profile"