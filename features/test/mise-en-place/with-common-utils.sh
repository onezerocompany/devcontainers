#!/usr/bin/env bash

set -e

# Import test library
source dev-container-features-test-lib

# Test for with-common-utils scenario - verify mise works with common-utils feature
check "mise installed" command -v mise
check "mise version" mise --version

# Check shell integration for vscode user (remoteUser)
check "bash integration" bash -c 'if [ -f /home/vscode/.bashrc ]; then grep -q "mise activate bash" /home/vscode/.bashrc; else grep -q "mise activate bash" ~/.bashrc; fi'
check "bash auto-init" bash -c 'if [ -f /home/vscode/.bashrc ]; then grep -q "mise-init" /home/vscode/.bashrc; else grep -q "mise-init" ~/.bashrc; fi'
check "zsh integration exists" bash -c 'if command -v zsh >/dev/null 2>&1 && [ -f ~/.zshrc ]; then grep -q "mise activate zsh" ~/.zshrc; else echo "zsh not available or configured - OK"; fi'

# Check directories exist
check "cache directory exists" test -d ~/.cache/mise
check "config directory exists" test -d ~/.config/mise
check "installs directory exists" test -d ~/.local/share/mise

# Check mise-init script is installed
check "mise-init script exists" test -x /usr/local/bin/mise-init

# Check mise is accessible in PATH
check "mise in path" which mise | grep -q "/usr/local/bin/mise"

# Check common-utils integration
check "git installed" command -v git
check "curl installed" command -v curl

# Report results
reportResults