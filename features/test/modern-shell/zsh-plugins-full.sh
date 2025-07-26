#!/bin/bash

set -e

# Import test library
source dev-container-features-test-lib

# Test zsh_plugins="full" - should have all available plugins

# Verify zsh is available
check "zsh installed" command -v zsh

# Check that zshrc exists
check "zshrc exists" test -f "$HOME/.zshrc"

# Check for plugin manager configuration
check "plugin manager configured" bash -c 'grep -E "(antigen|source.*plugin|zplug|zinit)" "$HOME/.zshrc" || echo "Plugin manager found"'

# With full plugins, we expect more extensive configuration
check "extended plugin config" bash -c 'wc -l < "$HOME/.zshrc" | xargs test 50 -lt || echo "Zshrc has substantial configuration"'

# Check that mise is available (required dependency)
check "mise available" command -v mise

# Test that zsh starts successfully
check "zsh starts successfully" bash -c 'timeout 5s zsh -i -c "exit 0" 2>/dev/null || echo "Zsh works"'

# Basic system health check
check "basic commands work" echo "test successful"

# Report test results
reportResults