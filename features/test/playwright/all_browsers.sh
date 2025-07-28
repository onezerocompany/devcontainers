#!/bin/bash

# This test file is used to test the playwright devcontainer feature
# It uses the dev-container-features-test-lib

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
# The 'check' command comes from the dev-container-features-test-lib

# Check if bun or npm is available for playwright
if command -v bun >/dev/null 2>&1; then
    check "bun installed" bash -c "command -v bun"
    check "playwright installed" bash -c "bunx playwright --version"
    check "playwright can show help" bash -c "bunx playwright --help | grep -q 'Usage'"
elif command -v npm >/dev/null 2>&1; then
    check "npm installed" bash -c "command -v npm"
    check "playwright installed" bash -c "npx playwright --version"
    check "playwright can show help" bash -c "npx playwright --help | grep -q 'Usage'"
else
    echo "ERROR: Neither bun nor npm found"
    exit 1
fi

# Check environment variables
check "playwright browsers path env var" bash -c "test -n \"\${PLAYWRIGHT_BROWSERS_PATH}\""
check "playwright skip download env var" bash -c "test -n \"\${PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD}\""

# Check that browsers directory exists
check "playwright browsers directory exists" bash -c "test -d \"/ms-playwright\""

# Check shell configuration files contain playwright env vars
check "bashrc contains playwright vars" bash -c "grep -q 'PLAYWRIGHT_BROWSERS_PATH' ~/.bashrc"
check "zshrc contains playwright vars" bash -c "grep -q 'PLAYWRIGHT_BROWSERS_PATH' ~/.zshrc || true"

# Check system-wide profile script
check "system profile script exists" bash -c "test -f /etc/profile.d/playwright.sh"

# Report results
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults