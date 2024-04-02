#!/bin/bash

source dev-container-features-test-lib

test() {
  zsh -c "source ~/.zshrc && $1"
}

# Definition specific tests
check "firebase" test "firebase --version"

# Report result
reportResults