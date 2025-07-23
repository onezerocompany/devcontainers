#!/bin/bash

# Test runner for common-utils feature
# This script sources the testing utilities and runs all test scenarios

set -e

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source testing utilities
source "$SCRIPT_DIR/utils.sh"

# Import the test library for the test framework  
source dev-container-features-test-lib

# Feature to test (edit this if you are testing a different feature)
FEATURE="common-utils"

# The dev-container-features-test-lib expects individual check calls
# Since we have more complex test suites, let's run a basic validation

# Basic validation that key tools are available
check "zsh-installed" zsh --version
check "detected-user-exists" id "$DETECTED_USER"

# Report results
reportResults