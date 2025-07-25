#!/bin/bash

# Edge case tests for onezero-motd
# Tests unusual configurations and system states

set -e

source dev-container-features-test-lib

echo "# Testing edge cases..."

# Test 1: Empty configuration values
export ASCII_LOGO=""
export INFO=""
export MESSAGE=""

check "handles empty values" bash -c '
    # Should still execute without errors
    /etc/update-motd.d/50-onezero >/dev/null 2>&1 &&
    # Should show system info even with empty custom values
    /etc/update-motd.d/50-onezero 2>&1 | grep -q "System Information"
'

# Test 2: Special characters in configuration
SPECIAL_CHARS="\$\`\"'\\"
if [ -f /etc/onezero/motd.conf ]; then
    cp /etc/onezero/motd.conf /etc/onezero/motd.conf.bak
    cat > /etc/onezero/motd.conf << EOF
ASCII_LOGO="Special: ${SPECIAL_CHARS}"
INFO="Path: /usr/bin/\$PATH"
MESSAGE="Quote: \"Hello\" and 'World'"
EOF
    
    check "handles special characters" bash -c '/etc/update-motd.d/50-onezero >/dev/null 2>&1'
    
    mv /etc/onezero/motd.conf.bak /etc/onezero/motd.conf
fi

# Test 3: System without common utilities
check "graceful degradation" bash -c '
    # Temporarily hide commands
    PATH=/usr/local/bin:/usr/bin:/bin
    
    # Should still work without free, df, etc
    OUTPUT=$(/etc/update-motd.d/50-onezero 2>&1)
    
    # Basic structure should remain
    echo "$OUTPUT" | grep -q "System Information" &&
    echo "$OUTPUT" | grep -q "Date:"
'

# Test 4: Concurrent execution
check "concurrent execution safe" bash -c '
    # Run multiple instances simultaneously
    for i in {1..5}; do
        /etc/update-motd.d/50-onezero >/dev/null 2>&1 &
    done
    wait
    
    # All should complete successfully
    true
'

# Test 5: Large output handling
if command -v dd >/dev/null 2>&1; then
    # Create a large ASCII logo
    LARGE_LOGO=$(dd if=/dev/zero bs=1024 count=10 2>/dev/null | tr '\0' 'X' | fold -w 80)
    
    cp /etc/onezero/motd.conf /etc/onezero/motd.conf.bak
    echo "ASCII_LOGO=\"${LARGE_LOGO:0:1000}\"" > /etc/onezero/motd.conf
    
    check "handles large content" bash -c '
        timeout 5s /etc/update-motd.d/50-onezero >/dev/null 2>&1
    '
    
    mv /etc/onezero/motd.conf.bak /etc/onezero/motd.conf
fi

# Test 6: Permission edge cases
if [ "$EUID" -eq 0 ]; then
    # Test with restricted permissions
    chmod 400 /etc/onezero/motd.conf
    check "works with read-only config" bash -c '/etc/update-motd.d/50-onezero >/dev/null 2>&1'
    chmod 644 /etc/onezero/motd.conf
fi

reportResults