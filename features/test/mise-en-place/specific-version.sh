#!/usr/bin/env bash

set -e

# Import test library
source dev-container-features-test-lib

# Test specific version installation (2024.1.0)

check "mise installed" command -v mise

# Check that mise reports the correct version
check "mise version 2024.1.0" bash -c 'mise --version | grep -q "2024.1.0"'

# Verify other standard features still work
check "bash integration" grep -q "mise activate bash" ~/.bashrc
check "mise-init script exists" test -x /usr/local/bin/mise-init
check "cache directory exists" test -d ~/.cache/mise
check "config directory exists" test -d ~/.config/mise
check "installs directory exists" test -d ~/.local/share/mise

# Report results
reportResults