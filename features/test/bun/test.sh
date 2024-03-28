#!/bin/zsh

# Optional: Import test library
source dev-container-features-test-lib

check "bun" bash --version

# Report result
reportResults