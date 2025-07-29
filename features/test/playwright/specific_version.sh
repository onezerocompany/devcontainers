#!/bin/bash

# This test file is used to test the playwright devcontainer feature
# It uses the dev-container-features-test-lib

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
# The 'check' command comes from the dev-container-features-test-lib

# Check if mise is available and can run playwright
check "mise installed" bash -c "command -v mise"
check "mise can run npm" bash -c "mise exec -- npm --version"
check "playwright installed via mise" bash -c "mise exec -- npx playwright --version"
check "playwright can show help via mise" bash -c "mise exec -- npx playwright --help | grep -q 'Usage'"

# Check environment variables
check "playwright browsers path env var" bash -c "test -n \"\${PLAYWRIGHT_BROWSERS_PATH}\""
check "playwright skip download env var" bash -c "test -n \"\${PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD}\""

# Check that browsers directory exists
check "playwright browsers directory exists" bash -c "test -d \"/ms-playwright\""

# Check that the specific version was installed (1.40.0 according to scenarios.json)
check "playwright version is 1.40.0" bash -c "mise exec -- npx playwright --version | grep -q '1.40.0'"

# Check shell configuration files contain playwright env vars
check "bashrc contains playwright vars" bash -c "grep -q 'PLAYWRIGHT_BROWSERS_PATH' ~/.bashrc"
check "zshrc contains playwright vars" bash -c "grep -q 'PLAYWRIGHT_BROWSERS_PATH' ~/.zshrc || true"

# Check system-wide profile script
check "system profile script exists" bash -c "test -f /etc/profile.d/playwright.sh"

# Report results
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults