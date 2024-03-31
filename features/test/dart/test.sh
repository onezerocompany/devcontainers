#!/bin/bash

source dev-container-features-test-lib

test() {
  zsh -c "source ~/.zshrc && $1"
}

# Definition specific tests
check "dart" test "dart --version"

# Report result
reportResults