#!/bin/bash

set -e

# Import test library and helpers
source dev-container-features-test-lib
source test-helpers.sh

# Test install_neovim=false

# Check that neovim is NOT installed
check_not "neovim not installed" command -v nvim
check_not "neovim not available" which nvim

# Check that vi/vim aliases to nvim are NOT created
check_not_in_file "no vi alias in bashrc" "alias vi.*nvim" "$HOME/.bashrc"
check_not_in_file "no vim alias in bashrc" "alias vim.*nvim" "$HOME/.bashrc"
check_not_in_file "no vi alias in zshrc" "alias vi.*nvim" "$HOME/.zshrc"
check_not_in_file "no vim alias in zshrc" "alias vim.*nvim" "$HOME/.zshrc"

# Other features should still work
check "zsh installed" command -v zsh
check "mise available" command -v mise
check "shell configuration exists" test -f "$HOME/.zshrc"

# Report test results
reportResults