#!/bin/bash

# This test file will be executed against an auto-generated devcontainer.json
# that includes the feature with no options
set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
# Test that default shell is zsh
check "default-shell" bash -c "getent passwd $(whoami) | cut -d: -f7 | grep -q '/bin/zsh'"

# Test that starship is installed
check "starship" which starship

# Test that zoxide is installed
check "zoxide" which zoxide

# Test that eza is installed
check "eza" which eza

# Test that bat is installed
check "bat" which bat

# Test that shell configs exist
check "bashrc" test -f ~/.bashrc
check "zshrc" test -f ~/.zshrc

# Test that starship config exists
check "starship-config" test -f ~/.config/starship.toml

# Test that our configuration was appended with markers
check "bashrc-markers" bash -c "grep -q '# >>> Modern Shell Tools - START >>>' ~/.bashrc"
check "zshrc-markers" bash -c "grep -q '# >>> Modern Shell Tools - START >>>' ~/.zshrc"

# Test aliases work in bash
check "eza-alias-bash" bash -c "source ~/.bashrc && alias ls | grep -q 'eza'"
check "bat-alias-bash" bash -c "source ~/.bashrc && alias cat | grep -q 'bat'"

# Report results
reportResults