#!/bin/bash

# Performance benchmark for onezero-motd tests
# Measures and compares different testing approaches

set -e

echo "=== OneZero MOTD Test Performance Benchmark ==="
echo "Environment: $(uname -s) $(uname -m)"
echo "Date: $(date)"
echo ""

# Helper to measure execution time
benchmark() {
    local name="$1"
    local cmd="$2"
    
    echo -n "$name: "
    
    # Warm up
    eval "$cmd" >/dev/null 2>&1 || true
    
    # Measure
    local start=$(date +%s.%N 2>/dev/null || date +%s)
    eval "$cmd" >/dev/null 2>&1
    local end=$(date +%s.%N 2>/dev/null || date +%s)
    
    # Calculate duration
    if command -v bc >/dev/null 2>&1; then
        local duration=$(echo "scale=3; $end - $start" | bc)
        echo "${duration}s"
    else
        echo "$((end - start))s"
    fi
}

# Test different approaches
echo "1. Individual Tests (Original Approach)"
benchmark "  File checks (3 separate)" '
    test -f /etc/update-motd.d/50-onezero
    test -x /etc/update-motd.d/50-onezero
    test -f /etc/onezero/motd.conf
'

benchmark "  MOTD execution (7 times)" '
    for i in {1..7}; do
        /etc/update-motd.d/50-onezero 2>/dev/null | grep -q "OneZero" || true
    done
'

echo ""
echo "2. Optimized Tests (Batched Approach)"
benchmark "  File checks (combined)" '
    [ -f /etc/update-motd.d/50-onezero ] && 
    [ -x /etc/update-motd.d/50-onezero ] && 
    [ -f /etc/onezero/motd.conf ]
'

benchmark "  MOTD execution (cached)" '
    OUTPUT=$(/etc/update-motd.d/50-onezero 2>&1)
    for i in {1..7}; do
        echo "$OUTPUT" | grep -q "OneZero" || true
    done
'

echo ""
echo "3. Ultra-Optimized (Single Pass)"
benchmark "  All checks combined" '
    OUTPUT=$(/etc/update-motd.d/50-onezero 2>&1) &&
    [ $? -eq 0 ] &&
    echo "$OUTPUT" | grep -q "OneZero" &&
    echo "$OUTPUT" | grep -q "System Information"
'

echo ""
echo "4. MOTD Execution Performance"
benchmark "  First run" '/etc/update-motd.d/50-onezero >/dev/null 2>&1'
benchmark "  Second run (cached)" '/etc/update-motd.d/50-onezero >/dev/null 2>&1'

# Memory usage estimate
if command -v /usr/bin/time >/dev/null 2>&1; then
    echo ""
    echo "5. Resource Usage"
    /usr/bin/time -f "  Memory: %M KB\n  CPU: %P" /etc/update-motd.d/50-onezero >/dev/null 2>&1 || true
fi

echo ""
echo "=== Recommendations ==="
echo "- Use cached output for multiple content checks"
echo "- Combine related file system operations"
echo "- Implement early exit on critical failures"
echo "- Consider parallel execution for independent tests"