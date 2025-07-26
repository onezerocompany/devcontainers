#!/bin/bash

set -e

# Import libraries
source dev-container-features-test-lib
SOURCE_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$SOURCE_DIR/test-helpers.sh" ]; then
    source "$SOURCE_DIR/test-helpers.sh"
else
    {
    # Fallback to basic testing
    export MOTD_OUTPUT CONFIG_CONTENT
    MOTD_OUTPUT=$(/etc/update-motd.d/50-onezero 2>&1)
    CONFIG_CONTENT=$(cat /etc/onezero/motd.conf 2>&1)
    
    check "custom setup" bash -c "
        [ -f /etc/update-motd.d/50-onezero ] &&
        [ -x /etc/update-motd.d/50-onezero ] &&
        [ -f /etc/onezero/motd.conf ]
    "
    
    check "custom content" bash -c "
        echo '\$MOTD_OUTPUT' | grep -q '___' &&
        echo '\$MOTD_OUTPUT' | grep -q 'Custom OneZero Container' &&
        echo '\$MOTD_OUTPUT' | grep -q \"Let's build something awesome!\"
    "
    
    reportResults
    exit 0
    }
fi

# Initialize
init_test_env

# Expected custom values (matching the scenario configuration)
# The ASCII logo from scenarios.json contains escaped characters, when rendered it contains ___ patterns
export EXPECTED_LOGO="/ _ \\\\"  # This appears in the rendered ASCII art
export EXPECTED_INFO="Custom OneZero Container"
export EXPECTED_MESSAGE="Let's build something awesome!"

# Phase 1: Installation check
check "custom motd installed" test "$(check_files_batch)" = "all_files_ok"

# Phase 2: Configuration validation (single read)
export CONFIG
CONFIG=$(get_config_content)
check "custom config stored" bash -c "
    # Check if config file contains our expected values (may be multiline)
    echo '\$CONFIG' | grep -q '\$EXPECTED_LOGO' &&
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

# Optional: Validate ASCII art integrity (check for any underscore patterns)
LOGO_LINES=$(echo "$OUTPUT" | grep -c "_" || true)
check "logo contains underscores" test "$LOGO_LINES" -ge 1

reportResults