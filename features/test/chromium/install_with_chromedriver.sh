#!/bin/bash

set -e

source dev-container-features-test-lib

# Feature-specific tests for chromedriver scenario
check "chromium version" bash -c "chromium --version || chromium-browser --version"
check "chromedriver installed" bash -c "which chromedriver"
check "chromedriver version" bash -c "chromedriver --version"

reportResults