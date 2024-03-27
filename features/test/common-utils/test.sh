#!/bin/bash -e

# Optional: Import test library
source dev-container-features-test-lib

check "zsh" zsh --version

# Report result
reportResults