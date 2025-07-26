#!/bin/bash

set -e

# Import test library and helpers
source dev-container-features-test-lib
source test-helpers.sh

# Test zsh_plugins="none" - no plugins should be installed

# Verify zsh is available
check "zsh installed" command -v zsh

# Check that no plugin directories exist
check_not "no antigen directory" test -d "$HOME/.antigen"
check_not "no oh-my-zsh directory" test -d "$HOME/.oh-my-zsh"

# Check that zshrc exists but doesn't contain plugin configurations
check "zshrc exists" test -f "$HOME/.zshrc"
check_not_in_file "no antigen in zshrc" "antigen" "$HOME/.zshrc"
check_not_in_file "no zsh-syntax-highlighting" "zsh-syntax-highlighting" "$HOME/.zshrc"
check_not_in_file "no zsh-autosuggestions" "zsh-autosuggestions" "$HOME/.zshrc"

# Basic functionality should still work
check "zsh starts successfully" zsh -c "echo 'zsh works'"

# Report test results
reportResults