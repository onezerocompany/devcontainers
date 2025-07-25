#!/usr/bin/env bash

set -e

# Import test library
source dev-container-features-test-lib

# Feature specific tests
check "mise installed" command -v mise
check "mise version" mise --version

# Check shell integration
check "bash integration" grep -q "mise activate bash" ~/.bashrc
check "bash auto-init" grep -q "mise-init" ~/.bashrc
check "zsh integration exists" bash -c 'if [ -f ~/.zshrc ]; then grep -q "mise activate zsh" ~/.zshrc; else echo "zsh not installed - skipping"; fi'

# Check directories exist
check "cache directory exists" test -d ~/.cache/mise
check "config directory exists" test -d ~/.config/mise
check "installs directory exists" test -d ~/.local/share/mise

# Check mise-init script is installed
check "mise-init script exists" test -x /usr/local/bin/mise-init

# Check mise is accessible in PATH
check "mise in path" which mise | grep -q "/usr/local/bin/mise"

# Report results
reportResults