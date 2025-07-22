#!/bin/bash

# Test minimal configuration where most tools are disabled
# This verifies the system works correctly when tools are turned off

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Test that shell files still exist
check "bashrc-exists" test -f ~/.bashrc
check "zshrc-exists" test -f ~/.zshrc
check "zshenv-exists" test -f ~/.zshenv

# Test that common-utils markers exist even when tools are disabled
check "bashrc-markers-exist" bash -c "grep -q '# >>> common-utils - START >>>' ~/.bashrc"
check "zshrc-markers-exist" bash -c "grep -q '# >>> common-utils - START >>>' ~/.zshrc"
check "zshenv-markers-exist" bash -c "grep -q '# >>> common-utils - START >>>' ~/.zshenv"

# Test that disabled tools are NOT configured
check "no-starship-config" bash -c "! grep -q 'starship init' ~/.bashrc && ! grep -q 'starship init' ~/.zshrc"
check "no-zoxide-config" bash -c "! grep -q 'zoxide init' ~/.bashrc && ! grep -q 'zoxide init' ~/.zshrc"
check "no-eza-config" bash -c "! grep -q \"alias ls='eza'\" ~/.bashrc && ! grep -q \"alias ls='eza'\" ~/.zshrc"

# Test that zshenv still has basic configuration
check "zshenv-has-basic-config" bash -c "grep -q 'PATH.*local/bin' ~/.zshenv"

# Test that sections are either empty or contain only basic configuration
check "minimal-bashrc-content" bash -c "
    content=\$(sed -n '/# >>> common-utils - START >>>/,/# <<< common-utils - END <<</p' ~/.bashrc | sed '/^#/d' | sed '/^[[:space:]]*$/d')
    [ -z \"\$content\" ] || echo \"\$content\" | grep -q 'PATH\\|EDITOR'
"

# Report results
reportResults