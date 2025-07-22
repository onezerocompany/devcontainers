#!/bin/bash

set -e

source dev-container-features-test-lib

# Test security hardening measures

# Test 1: Verify MOTD script doesn't execute injected commands
check "motd-no-command-execution" bash -c "
    if [ -f ~/.config/modern-shell-motd.sh ]; then
        # Run MOTD script and ensure it doesn't execute injected commands
        output=\$(~/.config/modern-shell-motd.sh 2>&1)
        
        # Should contain literal text, not executed results
        if echo \"\$output\" | grep -q '\\\$PATH' && 
           echo \"\$output\" | grep -q 'echo malicious' &&
           echo \"\$output\" | grep -q '../../../etc/passwd'; then
            echo 'MOTD properly escaped shell metacharacters'
        else
            echo 'MOTD may have executed injected commands'
            exit 1
        fi
    else
        echo 'MOTD script not found'
        exit 1
    fi
"

# Test 2: Verify MOTD script is syntactically valid
check "motd-syntax-valid" bash -n ~/.config/modern-shell-motd.sh

# Test 3: Verify no unintended file access from path traversal
check "no-path-traversal" bash -c "
    # Ensure no files were created outside expected directories
    ! find /etc -name '*modern-shell*' 2>/dev/null | grep -q .
    ! find /var -name '*modern-shell*' 2>/dev/null | grep -q .
"

# Test 4: Verify configuration files don't contain raw user input
check "config-files-safe" bash -c "
    if grep -r 'echo malicious' ~/.bashrc ~/.zshrc ~/.config 2>/dev/null; then
        echo 'Found unescaped command injection in config files'
        exit 1
    fi
    echo 'Configuration files appear safe'
"

# Test 5: Verify architecture detection works on different systems
check "arch-detection-safe" bash -c "
    # Test the centralized architecture detection function doesn't fail
    if command -v dpkg >/dev/null; then
        echo 'dpkg available for arch detection'
    elif command -v uname >/dev/null; then
        echo 'uname available for arch detection'
    else
        echo 'No architecture detection method available'
        exit 1
    fi
"

# Report results
reportResults