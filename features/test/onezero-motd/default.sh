#!/bin/bash

set -e

# Import libraries
source dev-container-features-test-lib
SOURCE_DIR="$(cd "$(dirname "$0")" && pwd)"
[ -f "$SOURCE_DIR/test-helpers.sh" ] && source "$SOURCE_DIR/test-helpers.sh" || {
    # Fallback to basic testing if helpers not available
    echo "# Warning: test-helpers.sh not found, using basic tests" >&2
    
    check "motd script exists" test -f /etc/update-motd.d/50-onezero
    check "motd script is executable" test -x /etc/update-motd.d/50-onezero
    check "config file exists" test -f /etc/onezero/motd.conf
    check "motd runs successfully" bash -c "/etc/update-motd.d/50-onezero >/dev/null 2>&1"
    
    MOTD_OUTPUT=$(/etc/update-motd.d/50-onezero 2>&1)
    check "motd content" bash -c "
        echo '\$MOTD_OUTPUT' | grep -q 'OneZero' &&
        echo '\$MOTD_OUTPUT' | grep -q 'System Information' &&
        echo '\$MOTD_OUTPUT' | grep -q 'Date:' &&
        echo '\$MOTD_OUTPUT' | grep -q 'Happy coding'
    "
    
    reportResults
    exit 0
}

# Initialize optimized test environment
init_test_env

# Phase 1: Installation validation (fail fast)
FILES_STATUS=$(check_files_batch)
check "motd installed correctly" test "$FILES_STATUS" = "all_files_ok"

[ "$FILES_STATUS" != "all_files_ok" ] && {
    echo "# ERROR: Installation failed - $FILES_STATUS" >&2
    reportResults
    exit 1
}

# Phase 2: Execution test
EXIT_CODE=$(get_motd_exit_code)
check "motd executes successfully" test "$EXIT_CODE" -eq 0

# Phase 3: Content validation (single pass)
REQUIRED="OneZero System.Information Date: Happy.coding"
OPTIONAL="CPU: Memory: Storage:"
check "motd content complete" test "$(validate_motd_content "$REQUIRED" "$OPTIONAL")" = "content_valid"

# Phase 4: System-specific features
OUTPUT=$(get_motd_output)
if echo "$OUTPUT" | grep -q "Storage:"; then
    check "storage info format" bash -c "echo '\$OUTPUT' | grep -E 'Storage:.*[0-9]+.*/.*/'"
fi

# Optional: Performance report
[ "${MOTD_TEST_PERF:-}" = "true" ] && report_test_performance >&2

reportResults