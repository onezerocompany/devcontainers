#!/bin/bash

source dev-container-features-test-lib

test () {
  zsh -c "source ~/.zshrc && $1"
}

check "mise" test "mise --version"
check "mise doctor" test "mise doctor"

# Report result
reportResults