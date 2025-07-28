#!/usr/bin/env bash

set -e

# Import test library
source dev-container-features-test-lib

# Test build cache copy functionality

check "mise installed" command -v mise
check "mise version" mise --version

# Check that MISE_CACHE_DIR is set
check "MISE_CACHE_DIR is set" bash -c 'echo $MISE_CACHE_DIR | grep -q "/opt/mise-cache"'

# Check cache directory exists
check "cache directory exists" test -d /opt/mise-cache

# Check build cache directory was cleaned up
check "build cache cleaned up" bash -c '! test -d /opt/mise-cache-build'

# Check that Node.js LTS is installed (default behavior)
check "node installed via mise" mise list | grep -q "node"

# Check mise-init script functionality
check "mise-init script exists" test -x /usr/local/bin/mise-init

# Verify the initialized marker exists
check "mise initialized marker" test -f ~/.local/share/mise/.initialized

# Report results
reportResults