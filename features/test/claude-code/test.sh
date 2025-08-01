#!/bin/bash

set -e

source dev-container-features-test-lib

# Feature-specific tests
check "mise installed" command -v mise
check "node available via mise" bash -c 'eval "$(mise activate bash)" && command -v node'

# Check if claude-code is available
check "claude-code executable" which claude-code || command -v claude-code

# Check environment variables
check "CLAUDE_CONFIG_DIR set" bash -c 'source /etc/profile.d/claude-code.sh && [ -n "$CLAUDE_CONFIG_DIR" ]'

# Report results
reportResults