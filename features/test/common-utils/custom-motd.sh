#!/bin/bash

# Test custom MOTD and optional features
set -e

source dev-container-features-test-lib

# Test that custom MOTD was set
check "custom-motd-exists" test -f ~/.config/modern-shell-motd.sh
check "custom-motd-content" bash -c "grep -q 'Welcome to Development Environment!' ~/.config/modern-shell-motd.sh"

# Test that default tools are still installed when bundles are enabled by default
check "starship" which starship
check "zoxide" which zoxide  
check "eza" which eza
check "bat" which bat

# Test that shell configs exist
check "bashrc" test -f ~/.bashrc
check "zshrc" test -f ~/.zshrc

# Test that core bundle tools are installed (since bundles default to true)
check "curl" which curl
check "git" which git

# Report results
reportResults