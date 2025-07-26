#!/bin/bash

set -e

# Import test library and helpers
source dev-container-features-test-lib
source test-helpers.sh

# Test zsh_plugins="none" - no plugins should be installed

# Verify zsh is available
check "zsh installed" command -v zsh

# Since zsh_plugins feature is not yet implemented, we just verify
# that zsh works normally without plugin configuration
check "zshrc exists" test -f "$HOME/.zshrc"

# The actual plugin implementation is not yet done, so for now we just ensure
# that modern-shell doesn't explicitly configure plugins in the shell files
check_not_in_file "no antigen in zshrc" "antigen" "$HOME/.zshrc"
check_not_in_file "no zsh-syntax-highlighting" "zsh-syntax-highlighting" "$HOME/.zshrc"
check_not_in_file "no zsh-autosuggestions" "zsh-autosuggestions" "$HOME/.zshrc"

# We don't check for plugin directory existence since they might be created
# by the base image or other features - we only care that our feature doesn't configure them

# Basic functionality should still work
check "zsh starts successfully" zsh -c "echo 'zsh works'"

# Report test results
reportResults