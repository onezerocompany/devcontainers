#!/bin/bash

# Optional: Import test library
source dev-container-features-test-lib

check "zoxide" cd --version | grep "zoxide"
check "eza" eza --version | grep "not found"
check "motd" cat /etc/motd | grep "No such file or directory"
check "auto-cd" grep "setopt auto_cd" ~/.zshrc | grep "No such file or directory"

# Report result
reportResults