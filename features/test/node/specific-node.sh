#!/bin/bash

source dev-container-features-test-lib

test() {
  zsh -c "source ~/.zshrc && $1"
}

# Definition specific tests
check "nvm" test "nvm --version"
check "node" test "node --version | grep -qE '^v20\.'"

# Report result
reportResults