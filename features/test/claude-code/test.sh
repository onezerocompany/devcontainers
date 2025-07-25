#!/bin/bash

set -e

source dev-container-features-test-lib

# Feature-specific tests
check "mise installed" command -v mise
check "claude-code installed via mise" mise list | grep -q "claude-code"

# Check if claude-code is available
check "claude-code executable" which claude-code || command -v claude-code || mise which claude-code

# Check environment variables
check "CLAUDE_CONFIG_DIR set" bash -c 'source /etc/profile.d/claude-code.sh && [ -n "$CLAUDE_CONFIG_DIR" ]'

# Check config directory exists
check "claude config directory exists" test -d "$HOME/.claude" || test -d "/opt/claude-config"

# Check mise activation in shells
if [ -f "$HOME/.bashrc" ]; then
  check "mise activation in bashrc" grep -q 'mise activate bash' "$HOME/.bashrc"
fi

if [ -f "$HOME/.zshrc" ]; then
  check "mise activation in zshrc" grep -q 'mise activate zsh' "$HOME/.zshrc"
fi

# Report results
reportResults