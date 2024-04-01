#!/bin/bash

source dev-container-features-test-lib

test() {
  zsh -c "source ~/.zshrc && $1"
}

# Definition specific tests
check "kubectl" test "kubectl version --client"
check "helm" test "helm version --client"

# Report result
reportResults