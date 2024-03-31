#!/bin/bash

source dev-container-features-test-lib

test() {
  zsh -c "source ~/.zshrc && $1"
}

check "dart" test "dart --version | grep -q '3.3.3'"

# Report result
reportResults