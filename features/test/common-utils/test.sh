#!/bin/zsh

source dev-container-features-test-lib

check "bash" which bash
check "zsh" which zsh
check "zoxide" which zoxide
check "eza" which eza
check "motd" test -f /etc/motd
check "auto-cd" cat ~/.zshrc | grep "setopt auto_cd"

# Report result
reportResults