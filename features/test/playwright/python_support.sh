#!/bin/bash

set -e

source dev-container-features-test-lib

# Feature-specific tests for Python support scenario
check "python3 installed" bash -c "command -v python3"
check "pip3 installed" bash -c "command -v pip3"
check "playwright python module" bash -c "python3 -c 'import playwright'"
check "playwright test wrapper" bash -c "test -x /usr/local/bin/playwright-test"

reportResults