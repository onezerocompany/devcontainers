#!/bin/bash

# This test file is used to test the chromium devcontainer feature
# It uses the dev-container-features-test-lib

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
# The 'check' command comes from the dev-container-features-test-lib
check "chromium version" bash -c "chromium --version || chromium-browser --version"
check "chrome binary env var" bash -c "test -n \"\${CHROME_BIN}\""
check "chromium flags env var" bash -c "test -n \"\${CHROMIUM_FLAGS}\""
check "chromium test wrapper exists" bash -c "test -x /usr/local/bin/chromium-test"
check "chromium runs headless" bash -c "chromium-test --headless --dump-dom https://example.com | grep -q 'Example Domain'"

# Report results
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults