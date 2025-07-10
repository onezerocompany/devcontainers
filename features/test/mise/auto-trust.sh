#!/bin/bash

source dev-container-features-test-lib

test () {
  zsh -c "source ~/.zshrc && $1"
}

# Basic mise checks
check "mise" test "mise --version"

# Check if MISE_TRUSTED_CONFIG_PATHS is set correctly
check "trusted paths env" test "echo \$MISE_TRUSTED_CONFIG_PATHS | grep -q '/workspaces'"
check "additional trusted path 1" test "echo \$MISE_TRUSTED_CONFIG_PATHS | grep -q '/tmp/test-trust'"
check "additional trusted path 2" test "echo \$MISE_TRUSTED_CONFIG_PATHS | grep -q '/home/zero/projects'"

# Report result
reportResults