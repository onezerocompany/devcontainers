#!/usr/bin/env bash

set -e

# Import test library
source dev-container-features-test-lib

# Test configureCache=false

check "mise installed" command -v mise
check "mise version" mise --version

# When configureCache is false, MISE_CACHE_DIR should not be set
check "MISE_CACHE_DIR not set" bash -c '[ -z "$MISE_CACHE_DIR" ]'

# The cache directory /opt/mise-cache should not exist
check "cache directory not created" bash -c '! test -d /opt/mise-cache'

# Check shell integration still works
check "bash integration" grep -q "mise activate bash" ~/.bashrc
check "mise-init script exists" test -x /usr/local/bin/mise-init

# Config and installs directories should still exist
check "config directory exists" test -d ~/.config/mise
check "installs directory exists" test -d ~/.local/share/mise

# Mise will use default cache location when MISE_CACHE_DIR is not set
check "mise works with default cache" mise --version

# Report results
reportResults