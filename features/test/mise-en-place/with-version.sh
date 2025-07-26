#!/usr/bin/env bash

set -e

# Import test library
source dev-container-features-test-lib

# Test for with-version scenario - verify specific version is installed
check "mise installed" command -v mise
check "mise specific version" bash -c 'mise --version | grep -q "2024.1.0"'

# Check shell integration
check "bash integration" grep -q "mise activate bash" ~/.bashrc
check "bash auto-init" grep -q "mise-init" ~/.bashrc
check "zsh integration exists" bash -c 'if command -v zsh >/dev/null 2>&1 && [ -f ~/.zshrc ]; then grep -q "mise activate zsh" ~/.zshrc; else echo "zsh not available or configured - OK"; fi'

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