#!/bin/bash

# Shared test helpers for onezero-motd
# Provides optimized testing utilities with caching and performance features

# Global caches
declare -g MOTD_OUTPUT_CACHE=""
declare -g MOTD_EXIT_CODE_CACHE=""
declare -g CONFIG_CONTENT_CACHE=""
declare -g SYSTEM_INFO_CACHE=""

# Performance tracking
declare -g TEST_START_TIME=""
declare -g TEST_OPERATIONS=0

# Initialize test environment
init_test_env() {
    TEST_START_TIME=$(date +%s.%N)
    TEST_OPERATIONS=0
    
    # Pre-cache system capabilities
    SYSTEM_INFO_CACHE=$(cat <<EOF
HAS_PROC_CPUINFO=$([ -f /proc/cpuinfo ] && echo "yes" || echo "no")
HAS_PROC_MEMINFO=$([ -f /proc/meminfo ] && echo "yes" || echo "no")
HAS_FREE=$(command -v free &>/dev/null && echo "yes" || echo "no")
HAS_DF=$(command -v df &>/dev/null && echo "yes" || echo "no")
HAS_NPROC=$(command -v nproc &>/dev/null && echo "yes" || echo "no")
HAS_BC=$(command -v bc &>/dev/null && echo "yes" || echo "no")
EOF
)
}

# Get MOTD output with caching
get_motd_output() {
    if [ -z "$MOTD_OUTPUT_CACHE" ]; then
        MOTD_OUTPUT_CACHE=$(/etc/update-motd.d/50-onezero 2>&1)
        MOTD_EXIT_CODE_CACHE=$?
        ((TEST_OPERATIONS++))
    fi
    echo "$MOTD_OUTPUT_CACHE"
}

# Get MOTD exit code
get_motd_exit_code() {
    if [ -z "$MOTD_EXIT_CODE_CACHE" ]; then
        get_motd_output >/dev/null
    fi
    echo "$MOTD_EXIT_CODE_CACHE"
}

# Get config content with caching
get_config_content() {
    if [ -z "$CONFIG_CONTENT_CACHE" ] && [ -f /etc/onezero/motd.conf ]; then
        CONFIG_CONTENT_CACHE=$(cat /etc/onezero/motd.conf 2>&1)
        ((TEST_OPERATIONS++))
    fi
    echo "$CONFIG_CONTENT_CACHE"
}

# Batch file existence and permission checks
check_files_batch() {
    local result=0
    
    # Build batch check command
    [ -f /etc/update-motd.d/50-onezero ] || result=1
    [ -x /etc/update-motd.d/50-onezero ] || result=2
    [ -f /etc/onezero/motd.conf ] || result=3
    
    case $result in
        0) echo "all_files_ok" ;;
        1) echo "motd_script_missing" ;;
        2) echo "motd_script_not_executable" ;;
        3) echo "config_missing" ;;
    esac
}

# Efficient content validation
validate_motd_content() {
    local output
    output=$(get_motd_output)
    local required_patterns="$1"
    local optional_patterns="$2"
    
    # Check required patterns
    for pattern in $required_patterns; do
        if ! echo "$output" | grep -q "$pattern"; then
            echo "missing_required:$pattern"
            return 1
        fi
    done
    
    # Check optional patterns (at least one must exist)
    if [ -n "$optional_patterns" ]; then
        local found_optional=false
        for pattern in $optional_patterns; do
            if echo "$output" | grep -q "$pattern"; then
                found_optional=true
                break
            fi
        done
        
        if [ "$found_optional" = false ]; then
            echo "missing_all_optional"
            return 1
        fi
    fi
    
    echo "content_valid"
    return 0
}

# System capability check
check_system_capability() {
    local capability="$1"
    echo "$SYSTEM_INFO_CACHE" | grep "^HAS_${capability}=" | cut -d= -f2
}

# Performance report
report_test_performance() {
    local end_time
    end_time=$(date +%s.%N)
    local duration
    duration=$(echo "$end_time - $TEST_START_TIME" | bc 2>/dev/null || echo "N/A")
    
    echo "# Test Performance Report"
    echo "Duration: ${duration}s"
    echo "Operations: $TEST_OPERATIONS"
    echo "Cached hits: $((TEST_OPERATIONS > 0 ? 100 - (TEST_OPERATIONS * 100 / 10) : 0))%"
}

# Optimized check function wrapper
check_optimized() {
    local description="$1"
    local test_func="$2"
    
    # Time individual check
    local start
    start=$(date +%s.%N 2>/dev/null || date +%s)
    
    check "$description" bash -c "$test_func"
    
    local end
    end=$(date +%s.%N 2>/dev/null || date +%s)
    local duration
    duration=$(echo "$end - $start" | bc 2>/dev/null || echo "0")
    
    # Log slow tests
    if [ "${MOTD_DEBUG:-}" = "true" ] && [ "$duration" != "0" ]; then
        echo "# Check '$description' took ${duration}s" >&2
    fi
}

# Export all functions
export -f init_test_env
export -f get_motd_output
export -f get_motd_exit_code
export -f get_config_content
export -f check_files_batch
export -f validate_motd_content
export -f check_system_capability
export -f report_test_performance
export -f check_optimized