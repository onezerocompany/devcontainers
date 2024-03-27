#!/bin/bash -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
# check "version" node --version
check "pnpm" pnpm -v
check "nvm" nvm --version
check "yarn" yarn --version

# Report result
reportResults