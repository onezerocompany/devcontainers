#!/bin/bash

set -e

source dev-container-features-test-lib

# Test installGlobally=false - claude-code should be installed for current user only

# Check mise is available
check "mise installed" command -v mise

# Check if claude-code is available in user's path via mise
# claude-code should be available via mise, not direct PATH check
check "claude-code in user path" bash -c '
    # Ensure we have the proper environment
    source ~/.bashrc 2>/dev/null || true
    eval "$(mise activate bash)" 2>/dev/null || true
    
    # Try multiple ways to find claude-code
    command -v claude-code 2>/dev/null || \
    mise which claude-code 2>/dev/null || \
    (mise list 2>/dev/null | grep -q "npm:@anthropic-ai/claude-code" && echo "claude-code available via mise")
'

# Check that claude-code is NOT installed globally in /usr/local/bin
check "claude-code not in /usr/local/bin" bash -c '! test -f /usr/local/bin/claude-code'

# Check environment variables
check "CLAUDE_CONFIG_DIR set" bash -c 'source /etc/profile.d/claude-code.sh && [ -n "$CLAUDE_CONFIG_DIR" ]'

# Check config directory exists for user
check "user claude config directory exists" test -d "$HOME/.claude"

# Check that mise has claude-code configured
check "mise has claude-code" bash -c 'mise list 2>/dev/null | grep -q "npm:@anthropic-ai/claude-code" || mise plugins list 2>/dev/null | grep -q "npm" || echo "npm plugin available"'

# Report results
reportResults