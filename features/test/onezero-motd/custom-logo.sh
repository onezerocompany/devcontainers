#!/bin/bash

set -e

# Import libraries
source dev-container-features-test-lib
SOURCE_DIR="$(cd "$(dirname "$0")" && pwd)"
[ -f "$SOURCE_DIR/test-helpers.sh" ] && source "$SOURCE_DIR/test-helpers.sh" || {
    # Fallback to basic testing
    MOTD_OUTPUT=$(/etc/update-motd.d/50-onezero 2>&1)
    CONFIG_CONTENT=$(cat /etc/onezero/motd.conf 2>&1)
    
    check "custom setup" bash -c "
        [ -f /etc/update-motd.d/50-onezero ] &&
        [ -x /etc/update-motd.d/50-onezero ] &&
        [ -f /etc/onezero/motd.conf ]
    "
    
    check "custom content" bash -c "
        echo '\$MOTD_OUTPUT' | grep -q '_____' &&
        echo '\$MOTD_OUTPUT' | grep -q 'Custom OneZero Container' &&
        echo '\$MOTD_OUTPUT' | grep -q 'build something awesome'
    "
    
    reportResults
    exit 0
}

# Initialize
init_test_env

# Expected custom values
EXPECTED_LOGO="_____"
EXPECTED_INFO="Custom OneZero Container"
EXPECTED_MESSAGE="build something awesome"

# Phase 1: Installation check
check "custom motd installed" test "$(check_files_batch)" = "all_files_ok"

# Phase 2: Configuration validation (single read)
CONFIG=$(get_config_content)
check "custom config stored" bash -c "
    echo '\$CONFIG' | grep -F '\$EXPECTED_LOGO' >/dev/null &&
    echo '\$CONFIG' | grep -F '\$EXPECTED_INFO' >/dev/null &&
    echo '\$CONFIG' | grep -F '\$EXPECTED_MESSAGE' >/dev/null
"

# Phase 3: Runtime validation (single execution)
OUTPUT=$(get_motd_output)
check "custom values displayed" bash -c "
    echo '\$OUTPUT' | grep -F '\$EXPECTED_LOGO' >/dev/null &&
    echo '\$OUTPUT' | grep -F '\$EXPECTED_INFO' >/dev/null &&
    echo '\$OUTPUT' | grep -F '\$EXPECTED_MESSAGE' >/dev/null
"

# Phase 4: System info still present
check "system info preserved" bash -c "echo '\$OUTPUT' | grep -q 'System Information'"

# Optional: Validate ASCII art integrity
LOGO_LINES=$(echo "$OUTPUT" | grep -c "_" || true)
check "logo multi-line" test $LOGO_LINES -ge 2

reportResults