#!/bin/bash

set -e

source dev-container-features-test-lib

# Test that modern CLI tools are installed
check "starship" which starship
check "zoxide" which zoxide
check "eza" which eza
check "bat" which bat

# Test that shell configurations exist
check "bashrc" test -f ~/.bashrc
check "zshrc" test -f ~/.zshrc

# Test MOTD configuration exists
check "motd-script" test -f /usr/local/bin/devcontainer-info

# Test that basic tools are available
check "curl" which curl
check "git" which git
check "nmap" which nmap

# Report results
reportResults