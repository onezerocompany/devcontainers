#!/bin/bash

set -e

# Import test library and helpers
source dev-container-features-test-lib
source test-helpers.sh

# Test enable_completions=false

# Verify basic shell functionality
check "zsh installed" command -v zsh
check "mise available" command -v mise

# Check that completion directories are not created
check_not "no zsh completions dir" test -d "$HOME/.zsh/completions"
# Only check bash completions if .bashrc exists
if [ -f "$HOME/.bashrc" ]; then
  check_not "no bash completions in profile" grep -q "bash-completion" "$HOME/.bashrc"
else
  check "no bash completions in profile" true
fi

# Check that zshrc doesn't have completion configuration
check "zshrc exists" test -f "$HOME/.zshrc"
check_not_in_file "no fpath modifications" "fpath.*completion" "$HOME/.zshrc"
check_not_in_file "no compinit" "compinit" "$HOME/.zshrc"

# Shell should still work normally
check "zsh works without completions" zsh -c "echo 'zsh works'"
check "bash works without completions" bash -c "echo 'bash works'"

# Report test results
reportResults