#!/usr/bin/env bash

set -e

# Import test library
source dev-container-features-test-lib

# Test deprecated installBun option

check "mise installed" command -v mise
check "mise version" mise --version

# Check shell integration
check "bash integration" grep -q "mise activate bash" ~/.bashrc

# Check directories exist
check "config directory exists" test -d ~/.config/mise
check "installs directory exists" test -d ~/.local/share/mise

# The installBun option is deprecated and should be ignored
# Just verify mise works correctly
check "mise works correctly" mise --version

# Report results
reportResults