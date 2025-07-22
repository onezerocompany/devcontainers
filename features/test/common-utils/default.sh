#!/bin/bash

set -e

source dev-container-features-test-lib

# Test that modern CLI tools are installed
check "starship" which starship
check "zoxide" which zoxide
check "eza" which eza
check "bat" which bat

# Test that basic tools are installed (webDev defaults to false, so no httpie)
check "curl" which curl
check "git" which git

# Test that utilities bundle tools are installed (utilities defaults to true)
check "networking-tools" which nmap

# Test that shell configurations exist
check "bashrc" test -f ~/.bashrc
check "zshrc" test -f ~/.zshrc

# Test that default shell is set correctly (should be zsh by default)
check "default-shell-zsh" bash -c "getent passwd root | cut -d: -f7 | grep -q zsh"

# Report results
reportResults