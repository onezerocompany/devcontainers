#!/bin/bash

source dev-container-features-test-lib

test () {
  zsh -c "source ~/.zshrc && $1"
}

check "bun" test "bun --version"

# Report result
reportResults