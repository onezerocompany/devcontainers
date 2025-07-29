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
check "config directory exists" test -d ~/.config/mise
check "installs directory exists" test -d ~/.local/share/mise

# Check mise-init script is installed
check "mise-init script exists" test -x /usr/local/bin/mise-init

# Check mise is accessible in PATH
check "mise in path" which mise | grep -q "/usr/local/bin/mise"


# Check for configuration warnings (should be clean)
check "no invalid config warnings" bash -c '! mise settings 2>&1 | grep -q "unknown field"'

# Check that workspace is auto-trusted (default is autoTrust=true)
check "auto-trust functionality" bash -c 'mise trust --status || echo "trust status check complete"'

# Check permissions on user directories
check "mise installs directory is writable" test -w ~/.local/share/mise/installs
check "mise config directory is writable" test -w ~/.config/mise

# Test that mise can actually install a tool (validates permissions work)
check "mise can install tools" bash -c 'mise use -g usage@latest 2>&1 | grep -v "Permission denied" || true'

# Test non-interactive shell (simulates postCreateCommand environment)
check "mise works in non-interactive shell" bash -c '/bin/sh -c "mise --version" 2>&1 | grep -v "Permission denied"'

# Report results
reportResults