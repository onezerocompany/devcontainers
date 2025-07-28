#!/usr/bin/env bash

set -e

# Import test library
source dev-container-features-test-lib

# Test specific version installation

check "mise installed" command -v mise

# Check that we have the specific version
check "mise version 2024.1.0" mise --version | grep -q "2024.1.0"

# Check shell integration
check "bash integration" grep -q "mise activate bash" ~/.bashrc

# Check directories exist
check "cache directory at /opt/mise-cache" test -d /opt/mise-cache
check "config directory exists" test -d ~/.config/mise
check "installs directory exists" test -d ~/.local/share/mise
check "MISE_CACHE_DIR is set" bash -c 'echo $MISE_CACHE_DIR | grep -q "/opt/mise-cache"'

# Report results
reportResults