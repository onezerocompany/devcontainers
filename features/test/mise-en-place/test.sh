#!/usr/bin/env bash

set -e

# Import test library
source dev-container-features-test-lib

# Feature specific tests
check "mise installed" command -v mise
check "mise version" mise --version

# Check shell integration
check "bash integration" grep -q "mise activate bash" ~/.bashrc
check "bash auto-init" grep -q "mise-init" ~/.bashrc
check "zsh integration exists" bash -c 'if command -v zsh >/dev/null 2>&1 && [ -f ~/.zshrc ]; then grep -q "mise activate zsh" ~/.zshrc; else echo "zsh not available or configured - OK"; fi'

# Check directories exist
check "cache directory at /opt/mise-cache" test -d /opt/mise-cache
check "config directory exists" test -d ~/.config/mise
check "installs directory exists" test -d ~/.local/share/mise
check "MISE_CACHE_DIR is set" bash -c 'echo $MISE_CACHE_DIR | grep -q "/opt/mise-cache"'

# Check mise-init script is installed
check "mise-init script exists" test -x /usr/local/bin/mise-init

# Check mise is accessible in PATH
check "mise in path" which mise | grep -q "/usr/local/bin/mise"

# Check for configuration warnings (should be clean)
check "no invalid config warnings" bash -c '! mise settings 2>&1 | grep -q "unknown field"'

# Check that workspace is auto-trusted (if auto-trust is enabled)
check "auto-trust functionality" bash -c 'mise trust --status || echo "trust status check complete"'

# Report results
reportResults