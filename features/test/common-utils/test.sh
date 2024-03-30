#!/bin/bash

source dev-container-features-test-lib

test() {
  zsh -c "source ~/.zshrc && $1"
}

check "zoxide" test "command -v zoxide"
check "eza" test "command -v eza"
check "motd" test "cat /etc/motd"
check "auto-cd" test "grep 'setopt auto_cd' ~/.zshrc"

# Report result
reportResults