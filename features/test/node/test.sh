#!/bin/zsh

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "nvm" nvm --version
check "node" node --version
check "pnpm" pnpm -v
check "yarn" yarn --version

# Report result
reportResults