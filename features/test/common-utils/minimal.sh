#!/bin/bash

set -e

source dev-container-features-test-lib

# Test that modern CLI tools are NOT installed (when disabled)
check "no-starship" bash -c "! which starship"
check "no-zoxide" bash -c "! which zoxide"
check "no-eza" bash -c "! which eza"

# Test that bat is still installed (default is true, not disabled in minimal)
check "bat" which bat

# Test that basic system tools are still available
check "bash" which bash
check "curl" which curl

# Test that shell configurations still exist
check "bashrc" test -f ~/.bashrc
check "zshrc" test -f ~/.zshrc

# Report results
reportResults