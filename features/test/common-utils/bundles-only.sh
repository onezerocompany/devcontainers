#!/bin/bash

set -e

source dev-container-features-test-lib

# Test that modern CLI tools are NOT installed (when disabled)
check "no-starship" bash -c "! which starship"
check "no-zoxide" bash -c "! which zoxide"
check "no-eza" bash -c "! which eza"
check "no-bat" bash -c "! which bat"

# Test that bundle tools ARE installed
check "httpie" which http
check "jq" which jq
check "curl" which curl
check "nmap" which nmap
check "git" which git
check "lazygit" which lazygit

# Test that shell configs still exist (for bundles)
check "bashrc" test -f ~/.bashrc
check "zshrc" test -f ~/.zshrc

# Report results
reportResults