#!/bin/bash

source dev-container-features-test-lib

test() {
  zsh -c "source ~/.zshrc && $1"
}

check "zoxide" test "command -v zoxide"
check "eza" test "command -v eza"
check "bat" test "command -v batcat"
check "starship" test "command -v starship"
check "starship-config" test "test -f ~/.config/starship.toml"
check "starship-init" test "grep 'starship init zsh' ~/.zshrc"
check "motd" test "cat /etc/motd"
check "auto-cd" test "grep 'setopt auto_cd' ~/.zshrc"

# Report result
reportResults