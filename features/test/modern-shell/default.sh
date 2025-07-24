#!/bin/bash

set -e

# Import test library
source dev-container-features-test-lib

# Import helper functions
source "$(dirname "$0")/test-helpers.sh"

# Test default scenario - verify default configuration

echo "=== Testing basic requirements ==="

# Check essential tools that should always be installed
check "zsh installed" command -v zsh
check "mise installed" command -v mise

# Note: Skipping tool checks (fd, rg, bat, eza, zoxide, starship) 
# as they may fail due to GitHub API rate limiting during tests

echo "=== Testing shell configurations ==="

# Get user info
current_user=${_REMOTE_USER:-$(whoami)}
if [ "$current_user" = "root" ]; then
    user_home="/root"
else
    user_home="/home/$current_user"
fi

# Check shell configuration files exist
check ".zshrc exists" [ -f "$user_home/.zshrc" ]
check ".bashrc exists" [ -f "$user_home/.bashrc" ]

echo "=== Testing zsh configuration ==="

# Check zsh configurations
check "zsh - modern aliases configured" grep -q "Modern CLI aliases" "$user_home/.zshrc"
check "zsh - eza alias configured" grep -q "alias ls='eza" "$user_home/.zshrc"
check "zsh - bat alias configured" grep -q "alias cat='bat" "$user_home/.zshrc"
check "zsh - fd alias configured" grep -q "alias find='fd'" "$user_home/.zshrc"
check "zsh - rg alias configured" grep -q "alias grep='rg'" "$user_home/.zshrc"
check "zsh - auto_cd enabled (default)" grep -q "setopt AUTO_CD" "$user_home/.zshrc"
check "zsh - starship configured (default)" grep -q 'eval "$(starship init zsh)"' "$user_home/.zshrc"
check_not_in_file "zsh - zoxide NOT configured (default false)" "alias cd='z'" "$user_home/.zshrc"
check "zsh - mise activation" grep -q 'eval "$(mise activate zsh)"' "$user_home/.zshrc"
check "zsh - history configuration" grep -q "# Shell history configuration" "$user_home/.zshrc"
check "zsh - history size 10000 (default)" grep -q "HISTSIZE=10000" "$user_home/.zshrc"

echo "=== Testing bash configuration ==="

# Check bash configurations
check "bash - modern aliases configured" grep -q "Modern CLI aliases" "$user_home/.bashrc"
check "bash - eza alias configured" grep -q "alias ls='eza" "$user_home/.bashrc"
check "bash - bat alias configured" grep -q "alias cat='bat" "$user_home/.bashrc"
check "bash - fd alias configured" grep -q "alias find='fd'" "$user_home/.bashrc"
check "bash - rg alias configured" grep -q "alias grep='rg'" "$user_home/.bashrc"
check "bash - starship configured" grep -q 'eval "$(starship init bash)"' "$user_home/.bashrc"
check "bash - mise activation" grep -q 'eval "$(mise activate bash)"' "$user_home/.bashrc"
check "bash - history configuration" grep -q "# Shell history configuration" "$user_home/.bashrc"
check "bash - history size 10000 (default)" grep -q "export HISTSIZE=10000" "$user_home/.bashrc"

echo "=== Testing starship configuration ==="

# Check starship config
check "starship config exists" [ -f "$user_home/.config/starship.toml" ]

echo "=== Testing PATH configuration ==="

# Check PATH configurations
check "zshenv exists" [ -f "$user_home/.zshenv" ]
check "PATH in .zshenv" grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$user_home/.zshenv"
check "PATH in .bashrc" grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$user_home/.bashrc"

echo "=== Testing root user configuration ==="

# Check root configurations with sudo since tests run as non-root user
check "root .zshrc exists" sudo test -f "/root/.zshrc"
check "root .bashrc exists" sudo test -f "/root/.bashrc"
check "root zsh aliases" sudo grep -q "Modern CLI aliases" "/root/.zshrc"
check "root bash aliases" sudo grep -q "Modern CLI aliases" "/root/.bashrc"
check "root starship config" sudo test -f "/root/.config/starship.toml"

# Report test results
reportResults