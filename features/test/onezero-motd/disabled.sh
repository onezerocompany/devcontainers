#!/bin/bash

set -e

# Import test library
source dev-container-features-test-lib

# Optimized disabled state validation
# Single filesystem check for all artifacts
ARTIFACTS_FOUND=0
[ -f /etc/update-motd.d/50-onezero ] && ((ARTIFACTS_FOUND++))
[ -d /etc/onezero ] && ((ARTIFACTS_FOUND++))
[ -f /etc/onezero/motd.conf ] && ((ARTIFACTS_FOUND++))

# Single test for all conditions
check "motd artifacts absent" test $ARTIFACTS_FOUND -eq 0

# Optional: Verify other MOTD scripts remain untouched
if [ -d /etc/update-motd.d ]; then
    ORIGINAL_MOTD_COUNT=$(find /etc/update-motd.d -name "*.bak" 2>/dev/null | wc -l)
    check "no motd modifications" test $ORIGINAL_MOTD_COUNT -eq 0
fi

reportResults