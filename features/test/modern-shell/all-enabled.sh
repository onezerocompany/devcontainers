#!/bin/bash

set -e

# Import test library
source dev-container-features-test-lib

# Test all-enabled scenario - everything turned on

echo "=== Testing basic requirements ==="

# Check essential tools that should always be installed
check "zsh installed" command -v zsh
check "mise installed" command -v mise

# Note: Skipping tool version checks (fd, rg, bat, eza, zoxide, starship) 
# as they may fail due to GitHub API rate limiting during tests

# Get user info
current_user=${_REMOTE_USER:-$(whoami)}
if [ "$current_user" = "root" ]; then
    user_home="/root"
else
    user_home="/home/$current_user"
fi

echo "=== Testing zsh configuration ==="

# Check all features enabled in zsh
check "zsh - auto_cd enabled" grep -q "setopt AUTO_CD" "$user_home/.zshrc"
check "zsh - starship configured" grep -q 'eval "$(starship init zsh)"' "$user_home/.zshrc"
check "zsh - zoxide configured" grep -q "# Zoxide configuration" "$user_home/.zshrc"
check "zsh - zoxide init" grep -q 'eval "$(zoxide init zsh)"' "$user_home/.zshrc"
check "zsh - cd aliased to z" grep -q "alias cd='z'" "$user_home/.zshrc"
check "zsh - custom history size 20000" grep -q "HISTSIZE=20000" "$user_home/.zshrc"

# Check all aliases enabled
check "zsh - ls alias" grep -q "alias ls='eza" "$user_home/.zshrc"
check "zsh - ll alias" grep -q "alias ll='eza -l" "$user_home/.zshrc"
check "zsh - la alias" grep -q "alias la='eza -la" "$user_home/.zshrc"
check "zsh - lt alias" grep -q "alias lt='eza --tree" "$user_home/.zshrc"
check "zsh - cat alias" grep -q "alias cat='bat" "$user_home/.zshrc"
check "zsh - find alias" grep -q "alias find='fd'" "$user_home/.zshrc"
check "zsh - grep alias" grep -q "alias grep='rg'" "$user_home/.zshrc"

# Check custom aliases
check "zsh - custom aliases section" grep -q "# Custom aliases" "$user_home/.zshrc"
check "zsh - custom alias g" grep -q "alias g='git status'" "$user_home/.zshrc"
check "zsh - custom alias dc" grep -q "alias dc='docker compose'" "$user_home/.zshrc"
check "zsh - custom alias k" grep -q "alias k='kubectl'" "$user_home/.zshrc"

echo "=== Testing bash configuration ==="

# Check all features enabled in bash
check "bash - starship configured" grep -q 'eval "$(starship init bash)"' "$user_home/.bashrc"
check "bash - zoxide configured" grep -q "# Zoxide configuration" "$user_home/.bashrc"
check "bash - zoxide init" grep -q 'eval "$(zoxide init bash)"' "$user_home/.bashrc"
check "bash - cd aliased to z" grep -q "alias cd='z'" "$user_home/.bashrc"
check "bash - custom history size 20000" grep -q "export HISTSIZE=20000" "$user_home/.bashrc"

# Check all aliases enabled in bash
check "bash - ls alias" grep -q "alias ls='eza" "$user_home/.bashrc"
check "bash - cat alias" grep -q "alias cat='bat" "$user_home/.bashrc"
check "bash - find alias" grep -q "alias find='fd'" "$user_home/.bashrc"
check "bash - grep alias" grep -q "alias grep='rg'" "$user_home/.bashrc"

# Check custom aliases in bash
check "bash - custom aliases" grep -q "# Custom aliases" "$user_home/.bashrc"
check "bash - custom alias g" grep -q "alias g='git status'" "$user_home/.bashrc"
check "bash - custom alias dc" grep -q "alias dc='docker compose'" "$user_home/.bashrc"
check "bash - custom alias k" grep -q "alias k='kubectl'" "$user_home/.bashrc"

echo "=== Testing root configuration ==="

# Verify root has same configuration
check "root zsh - zoxide configured" grep -q "alias cd='z'" "/root/.zshrc"
check "root bash - zoxide configured" grep -q "alias cd='z'" "/root/.bashrc"
check "root - custom aliases in zsh" grep -q "alias g='git status'" "/root/.zshrc"
check "root - custom aliases in bash" grep -q "alias g='git status'" "/root/.bashrc"

# Report test results
reportResults