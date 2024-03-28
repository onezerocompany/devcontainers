#!/bin/bash -e

# Optional: Import test library
source dev-container-features-test-lib

check "shell is zsh" echo $SHELL | grep zsh

check "bun" bun --version

# Report result
reportResults