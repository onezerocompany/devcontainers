#!/bin/bash

set -e

source dev-container-features-test-lib

# Test custom config directory
check "custom config dir exists" test -d "/opt/claude-config"
check "custom CLAUDE_CONFIG_DIR" bash -c 'source /etc/profile.d/claude-code.sh && echo $CLAUDE_CONFIG_DIR' | grep -q "/opt/claude-config"

reportResults