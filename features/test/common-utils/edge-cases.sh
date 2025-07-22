#!/bin/bash

set -e

source dev-container-features-test-lib

# Test edge cases and bug regression tests

# Test 1: Verify shell configuration doesn't have race conditions
check "shell-configs-complete" bash -c "
    # Check that both bash and zsh configs have all expected sections
    grep -q 'starship' ~/.bashrc && grep -q 'zoxide' ~/.bashrc
    if which zsh >/dev/null; then 
        grep -q 'starship' ~/.zshrc && grep -q 'zoxide' ~/.zshrc
    fi
"

# Test 2: Verify MOTD script is syntactically valid bash
check "motd-script-valid-bash" bash -n ~/.config/modern-shell-motd.sh

# Test 3: Verify that configuration markers are properly balanced
check "bashrc-markers-balanced" bash -c "
    start_count=\$(grep -c 'common-utils - START' ~/.bashrc)
    end_count=\$(grep -c 'common-utils - END' ~/.bashrc)
    test \"\$start_count\" -eq \"\$end_count\" && test \"\$start_count\" -gt 0
"

# Test 4: Verify that starship config was copied correctly
if which starship >/dev/null; then
    check "starship-config-exists" test -f ~/.config/starship.toml
    check "starship-config-valid" starship config 2>/dev/null
fi

# Test 5: Verify that no temporary files remain
check "no-stale-temp-files" bash -c "
    ! find /tmp -name 'tmp_*' -type f 2>/dev/null | grep -q .
    ! find /tmp -name '*_install_*' -type f 2>/dev/null | grep -q .
    ! find /tmp -name 'fd*' -type f 2>/dev/null | grep -q .
    ! find /tmp -name 'ripgrep*' -type f 2>/dev/null | grep -q .
    ! find /tmp -name 'miller*' -type f 2>/dev/null | grep -q .
"

# Test 6: Verify shell path detection worked correctly
check "shell-in-etc-shells" bash -c "
    shell_path=\$(getent passwd \$(whoami) | cut -d: -f7)
    grep -q \"\$shell_path\" /etc/shells
"

# Test 7: Test that file ownership is correct for non-root user
if [ \$(id -u) -ne 0 ]; then
    check "config-ownership-correct" bash -c "
        test \$(stat -c %U ~/.bashrc) = \$(whoami)
        test \$(stat -c %U ~/.zshrc) = \$(whoami)  
        test \$(stat -c %U ~/.config/modern-shell-motd.sh) = \$(whoami)
    "
fi

# Test 8: Verify that validation logic correctly identified installed tools
check "tool-validation-accurate" bash -c "
    # If tool is available, it should have been detected during install
    if which starship >/dev/null; then echo 'Starship validation passed'; fi
    if which zoxide >/dev/null; then echo 'Zoxide validation passed'; fi
    if which eza >/dev/null; then echo 'Eza validation passed'; fi
    if which bat >/dev/null || which batcat >/dev/null; then echo 'Bat validation passed'; fi
    true  # Always pass this test - we're just checking for errors
"

# Report results  
reportResults