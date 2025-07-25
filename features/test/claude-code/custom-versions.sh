#!/bin/bash

set -e

source dev-container-features-test-lib

# Test custom versions
check "claude-code latest" mise list | grep -q "claude-code.*latest"

reportResults