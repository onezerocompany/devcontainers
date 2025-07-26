#!/bin/bash

set -e

source dev-container-features-test-lib

# Custom versions scenario test - verify claude-code works with specific version
check "claude-code command exists" command -v claude-code

# Check mise is available
check "mise installed" command -v mise

# Check environment variables
check "CLAUDE_CONFIG_DIR set" bash -c 'source /etc/profile.d/claude-code.sh && [ -n "$CLAUDE_CONFIG_DIR" ]'

# Report results
reportResults