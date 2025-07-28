#!/bin/bash

# This test file is used to test the playwright devcontainer feature
# It uses the dev-container-features-test-lib

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
# The 'check' command comes from the dev-container-features-test-lib
check "node installed" bash -c "command -v node"
check "npm installed" bash -c "command -v npm"
check "playwright installed" bash -c "npx playwright --version"
check "playwright env vars" bash -c "test -n \"\${PLAYWRIGHT_BROWSERS_PATH}\""
check "playwright test wrapper exists" bash -c "test -x /usr/local/bin/playwright-test"
check "playwright can show help" bash -c "npx playwright --help | grep -q 'Usage'"

# Report results
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults