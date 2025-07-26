#!/usr/bin/env bash

set -e

# Import test library
source dev-container-features-test-lib

# Test deprecated useBunForNpm=true option
# This option is deprecated and should be ignored, but the feature should still work

check "mise installed" command -v mise
check "mise version" mise --version

# The deprecated option should not affect normal operation
check "bash integration" grep -q "mise activate bash" ~/.bashrc
check "mise-init script exists" test -x /usr/local/bin/mise-init

# Standard directories should exist
check "cache directory exists" test -d ~/.cache/mise
check "config directory exists" test -d ~/.config/mise
check "installs directory exists" test -d ~/.local/share/mise

# The deprecated option should not configure bun as npm backend
# (mise removed this feature)
check "no bun npm configuration" bash -c '! mise settings 2>&1 | grep -q "bun.*npm"'

# Report results
reportResults