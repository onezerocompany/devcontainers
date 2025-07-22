#!/bin/bash

# Test compatibility with our base image that already has some tools installed
# This ensures common-utils works correctly when tools are pre-installed

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Test that tools from base image are still available
check "starship-available" command -v starship
check "zoxide-available" command -v zoxide
check "eza-available" command -v eza
check "bat-available" command -v bat

# Test that our common-utils markers exist (should be added by our feature)
check "bashrc-common-utils-markers" bash -c "grep -q '# >>> common-utils - START >>>' ~/.bashrc"
check "zshrc-common-utils-markers" bash -c "grep -q '# >>> common-utils - START >>>' ~/.zshrc"

# Test that our configurations are present within the common-utils section
check "starship-config-in-common-utils" bash -c "sed -n '/# >>> common-utils - START >>>/,/# <<< common-utils - END <<</p' ~/.bashrc | grep -q 'starship init'"
check "zoxide-config-in-common-utils" bash -c "sed -n '/# >>> common-utils - START >>>/,/# <<< common-utils - END <<</p' ~/.zshrc | grep -q 'zoxide init'"

# Test that aliases from common-utils are present
check "eza-alias-from-common-utils" bash -c "sed -n '/# >>> common-utils - START >>>/,/# <<< common-utils - END <<</p' ~/.bashrc | grep -q \"alias ls='eza'\""
check "bat-alias-from-common-utils" bash -c "sed -n '/# >>> common-utils - START >>>/,/# <<< common-utils - END <<</p' ~/.zshrc | grep -q \"alias cat='bat --paging=never'\""

# Test that tools still work correctly after common-utils configuration
check "starship-works" bash -c "starship --version"
check "zoxide-works" bash -c "zoxide --version"
check "eza-works" bash -c "eza --version"
check "bat-works" bash -c "bat --version"

# Test that shell aliases work
check "ls-alias-works" bash -c "source ~/.bashrc && type ls | grep -q 'eza'"
check "cat-alias-works" bash -c "source ~/.zshrc && type cat | grep -q 'bat'"

# Test that no conflicting configurations exist
# (This would fail if there are duplicate tool initializations)
check "no-duplicate-starship-init" bash -c "[ $(grep -c 'starship init' ~/.bashrc) -le 2 ]"
check "no-duplicate-zoxide-init" bash -c "[ $(grep -c 'zoxide init' ~/.zshrc) -le 2 ]"

# Report results
reportResults