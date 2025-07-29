#!/usr/bin/env bash

set -e

# Import test library
source dev-container-features-test-lib

# Test autoTrust=false

check "mise installed" command -v mise
check "mise version" mise --version

# Check shell integration
check "bash integration" grep -q "mise activate bash" ~/.bashrc
check "mise-init script exists" test -x /usr/local/bin/mise-init

# When autoTrust is false, the workspace should NOT be automatically trusted
# We can't easily test this without a .mise.toml file, but we can verify
# that the trust command works
check "mise trust command available" bash -c 'mise trust --help >/dev/null 2>&1'

# Standard directories should still exist
check "config directory exists" test -d ~/.config/mise
check "installs directory exists" test -d ~/.local/share/mise

# Report results
reportResults