#!/bin/bash

set -e

source dev-container-features-test-lib

# Feature-specific tests
check "mise installed" command -v mise
check "bun available via mise" bash -c 'eval "$(mise activate bash)" && command -v bun'

# Check if claude-code is available
check "claude-code executable" which claude-code || command -v claude-code

# Check environment variables
check "CLAUDE_CONFIG_DIR set" bash -c 'source /etc/profile.d/claude-code.sh && [ -n "$CLAUDE_CONFIG_DIR" ]'

# Check config directory exists
check "claude config directory exists" test -d "$HOME/.claude" || test -d "/opt/claude-config"

# Report results
reportResults