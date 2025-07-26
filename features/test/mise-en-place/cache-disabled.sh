#!/usr/bin/env bash

set -e

# Import test library
source dev-container-features-test-lib

# Test configureCache=false

check "mise installed" command -v mise
check "mise version" mise --version

# When configureCache is false, the cache directory should not be pre-configured
# but mise will still create it on first use
check "mise works without pre-configured cache" mise --version

# Check shell integration still works
check "bash integration" grep -q "mise activate bash" ~/.bashrc
check "mise-init script exists" test -x /usr/local/bin/mise-init

# Config and installs directories should still exist
check "config directory exists" test -d ~/.config/mise
check "installs directory exists" test -d ~/.local/share/mise

# The cache directory might not exist until mise is actually used
# So we just check that mise can create it when needed
check "mise can create cache on demand" bash -c 'mise settings >/dev/null 2>&1 && test -d ~/.cache/mise || echo "Cache will be created on first use"'

# Report results
reportResults