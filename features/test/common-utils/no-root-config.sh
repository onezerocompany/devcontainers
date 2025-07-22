#!/bin/bash

set -e

source dev-container-features-test-lib

# Test that modern CLI tools are installed for user
check "starship" which starship
check "zoxide" which zoxide
check "eza" which eza
check "bat" which bat

# Test that user shell configurations exist
check "user-bashrc" test -f ~/.bashrc
check "user-zshrc" test -f ~/.zshrc

# Test that root should NOT have the same configurations (configureForRoot: false)
# Note: This is hard to test in the test environment since we run as root
# But we can check that the feature installed correctly
check "basic-tools" which curl
check "git" which git

# Report results
reportResults