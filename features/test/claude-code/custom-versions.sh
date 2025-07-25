#!/bin/bash

set -e

source dev-container-features-test-lib

# Test custom versions
check "node version 20" mise list | grep -q "node.*20"
check "claude-code latest" mise list | grep -q "claude-code.*latest"

# Check custom max-old-space-size
check "custom NODE_OPTIONS" bash -c 'source /etc/profile.d/claude-code.sh && echo $NODE_OPTIONS' | grep -q "4096"

reportResults