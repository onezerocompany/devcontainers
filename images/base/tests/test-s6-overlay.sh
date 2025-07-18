#!/bin/bash
# Test script for s6-overlay functionality

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Track test results
TESTS_PASSED=0
TESTS_FAILED=0

# Utility functions
log_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

test_command() {
    local description="$1"
    local command="$2"
    local expected_exit_code="${3:-0}"
    
    eval "$command" >/dev/null 2>&1
    local exit_code=$?
    
    if [ $exit_code -eq $expected_exit_code ]; then
        log_success "$description"
        return 0
    fi
    
    log_error "$description (exit code: $exit_code, expected: $expected_exit_code)"
    return 1
}

# Test 1: S6-overlay installation
test_s6_installation() {
    log_info "Testing s6-overlay installation..."
    
    # Test s6-overlay binaries are installed
    test_command "s6-svscan is installed" "[ -x /command/s6-svscan ]"
    test_command "s6-rc is installed" "[ -x /command/s6-rc ]"
    test_command "s6-svstat is installed" "[ -x /command/s6-svstat ]"
    test_command "execlineb is installed" "[ -x /command/execlineb ]"
    
    # Test s6-overlay directories exist
    test_command "s6-overlay etc directory exists" "[ -d /etc/s6-overlay ]"
    test_command "s6-rc.d directory exists" "[ -d /etc/s6-overlay/s6-rc.d ]"
    
    # Test /init exists and is executable
    test_command "/init exists and is executable" "[ -x /init ]"
}

# Test 2: S6 service definitions (for DIND variant)
test_s6_service_definitions() {
    log_info "Testing s6 service definitions..."
    
    # Only test if DIND services exist
    if [ -d /etc/s6-overlay/s6-rc.d/dockerd ]; then
        # Test dockerd service
        test_command "dockerd service type file exists" "[ -f /etc/s6-overlay/s6-rc.d/dockerd/type ]"
        test_command "dockerd service is longrun" "grep -q '^longrun$' /etc/s6-overlay/s6-rc.d/dockerd/type"
        test_command "dockerd run script exists" "[ -x /etc/s6-overlay/s6-rc.d/dockerd/run ]"
        test_command "dockerd finish script exists" "[ -x /etc/s6-overlay/s6-rc.d/dockerd/finish ]"
        test_command "dockerd has dependencies directory" "[ -d /etc/s6-overlay/s6-rc.d/dockerd/dependencies.d ]"
        test_command "dockerd depends on base" "[ -e /etc/s6-overlay/s6-rc.d/dockerd/dependencies.d/base ]"
        
        # Test dockerd-log service
        test_command "dockerd-log service type file exists" "[ -f /etc/s6-overlay/s6-rc.d/dockerd-log/type ]"
        test_command "dockerd-log service is longrun" "grep -q '^longrun$' /etc/s6-overlay/s6-rc.d/dockerd-log/type"
        test_command "dockerd-log run script exists" "[ -x /etc/s6-overlay/s6-rc.d/dockerd-log/run ]"
        test_command "dockerd-log has dependencies directory" "[ -d /etc/s6-overlay/s6-rc.d/dockerd-log/dependencies.d ]"
        test_command "dockerd-log depends on base" "[ -e /etc/s6-overlay/s6-rc.d/dockerd-log/dependencies.d/base ]"
        
        # Test docker-permissions service
        test_command "docker-permissions service type file exists" "[ -f /etc/s6-overlay/s6-rc.d/docker-permissions/type ]"
        test_command "docker-permissions service is oneshot" "grep -q '^oneshot$' /etc/s6-overlay/s6-rc.d/docker-permissions/type"
        test_command "docker-permissions up script exists" "[ -x /etc/s6-overlay/s6-rc.d/docker-permissions/up ]"
        test_command "docker-permissions has dependencies directory" "[ -d /etc/s6-overlay/s6-rc.d/docker-permissions/dependencies.d ]"
        test_command "docker-permissions depends on dockerd" "[ -e /etc/s6-overlay/s6-rc.d/docker-permissions/dependencies.d/dockerd ]"
    else
        log_info "Docker services not present (standard variant)"
    fi
}

# Test 3: S6 log pipeline
test_s6_log_pipeline() {
    log_info "Testing s6 log pipeline configuration..."
    
    if [ -d /etc/s6-overlay/s6-rc.d/dockerd ]; then
        # Test log pipeline files
        test_command "dockerd producer-for file exists" "[ -f /etc/s6-overlay/s6-rc.d/dockerd/producer-for ]"
        test_command "dockerd produces logs for dockerd-log" "grep -q '^dockerd-log$' /etc/s6-overlay/s6-rc.d/dockerd/producer-for"
        
        test_command "dockerd-log consumer-for file exists" "[ -f /etc/s6-overlay/s6-rc.d/dockerd-log/consumer-for ]"
        test_command "dockerd-log consumes logs from dockerd" "grep -q '^dockerd$' /etc/s6-overlay/s6-rc.d/dockerd-log/consumer-for"
        
        test_command "dockerd-log notification-fd exists" "[ -f /etc/s6-overlay/s6-rc.d/dockerd-log/notification-fd ]"
    else
        log_info "Docker log pipeline not present (standard variant)"
    fi
}

# Test 4: S6 bundles
test_s6_bundles() {
    log_info "Testing s6 bundle configuration..."
    
    # Test user bundle exists
    test_command "user bundle exists" "[ -d /etc/s6-overlay/s6-rc.d/user ]"
    test_command "user bundle type file exists" "[ -f /etc/s6-overlay/s6-rc.d/user/type ]"
    test_command "user bundle is bundle type" "grep -q '^bundle$' /etc/s6-overlay/s6-rc.d/user/type"
    
    if [ -d /etc/s6-overlay/s6-rc.d/user/contents.d ]; then
        test_command "user bundle contents.d directory exists" "[ -d /etc/s6-overlay/s6-rc.d/user/contents.d ]"
        # Check that contents.d is empty or has proper files
        local contents_count=$(ls -1 /etc/s6-overlay/s6-rc.d/user/contents.d 2>/dev/null | wc -l)
        if [ "$contents_count" -eq 0 ]; then
            log_success "user bundle contents.d is properly empty"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            log_error "user bundle contents.d has unexpected files"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
    fi
}

# Test 5: S6 runtime (if container is running with s6)
test_s6_runtime() {
    log_info "Testing s6 runtime functionality..."
    
    # Skip runtime tests in CI build environment
    if [ -n "${CI}" ] || [ -n "${GITHUB_ACTIONS}" ]; then
        log_info "Skipping runtime tests in CI build environment"
        return
    fi
    
    # Check if s6-svscan is running
    if pgrep s6-svscan >/dev/null 2>&1; then
        test_command "s6-svscan is running" "pgrep s6-svscan"
        
        # Test s6-rc commands work
        test_command "s6-rc list works" "s6-rc list"
        test_command "s6-rc-db list works" "s6-rc-db list services"
        
        # Test service status commands (if DIND)
        if [ -d /etc/s6-overlay/s6-rc.d/dockerd ]; then
            # Wait a moment for services to stabilize
            sleep 2
            
            # Check dockerd service status
            if s6-rc -a list | grep -q dockerd; then
                test_command "dockerd service is active" "s6-svstat /run/service/dockerd | grep -q up"
                test_command "dockerd-log service is active" "s6-svstat /run/service/dockerd-log | grep -q up"
            fi
            
            # Check if docker socket exists and has correct permissions
            if [ -S /var/run/docker.sock ]; then
                test_command "Docker socket exists" "[ -S /var/run/docker.sock ]"
                test_command "Docker socket has correct permissions" "stat -c '%a' /var/run/docker.sock | grep -q '666'"
            fi
        fi
    else
        log_info "s6-svscan not running (expected during build)"
    fi
}

# Test 6: Service dependencies and ordering
test_service_dependencies() {
    log_info "Testing service dependencies..."
    
    if [ -d /etc/s6-overlay/s6-rc.d/dockerd ]; then
        # Check dependency files exist (static check for CI)
        if [ -f /etc/s6-overlay/s6-rc.d/dockerd/dependencies.d/base ]; then
            log_success "dockerd has base dependency file"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            log_error "dockerd missing base dependency file"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
        
        if [ -f /etc/s6-overlay/s6-rc.d/docker-permissions/dependencies.d/dockerd ]; then
            log_success "docker-permissions has dockerd dependency file"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            log_error "docker-permissions missing dockerd dependency file"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
        
        # Skip s6-rc-db checks in CI
        if [ -z "${CI}" ] && [ -z "${GITHUB_ACTIONS}" ] && command -v s6-rc-db >/dev/null 2>&1; then
            # Check dockerd dependencies
            local dockerd_deps=$(s6-rc-db dependencies dockerd 2>/dev/null || echo "")
            if echo "$dockerd_deps" | grep -q "base"; then
                log_success "dockerd correctly depends on base (runtime check)"
                TESTS_PASSED=$((TESTS_PASSED + 1))
            else
                log_error "dockerd missing base dependency (runtime check)"
                TESTS_FAILED=$((TESTS_FAILED + 1))
            fi
            
            # Check docker-permissions dependencies
            local perms_deps=$(s6-rc-db dependencies docker-permissions 2>/dev/null || echo "")
            if echo "$perms_deps" | grep -q "dockerd"; then
                log_success "docker-permissions correctly depends on dockerd (runtime check)"
                TESTS_PASSED=$((TESTS_PASSED + 1))
            else
                log_error "docker-permissions missing dockerd dependency (runtime check)"
                TESTS_FAILED=$((TESTS_FAILED + 1))
            fi
        else
            log_info "Runtime dependency checks skipped (CI environment or s6-rc-db not available)"
        fi
    else
        log_info "Docker services not present for dependency testing"
    fi
}

# Test 7: Log directory and rotation
test_log_management() {
    log_info "Testing log management..."
    
    if [ -d /etc/s6-overlay/s6-rc.d/dockerd-log ]; then
        # Check if log directory will be created
        local log_run_script="/etc/s6-overlay/s6-rc.d/dockerd-log/run"
        if grep -q "s6-mkdir.*\/var\/log\/services\/dockerd" "$log_run_script"; then
            log_success "dockerd-log creates log directory"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            log_error "dockerd-log doesn't create log directory"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
        
        # Check if s6-log is configured with rotation
        if grep -q "s6-log.*n[0-9].*s[0-9]" "$log_run_script"; then
            log_success "dockerd-log has log rotation configured"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            log_error "dockerd-log missing log rotation configuration"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
    else
        log_info "Docker log service not present"
    fi
}

# Main test execution
main() {
    log_info "Starting s6-overlay tests..."
    echo "================================"
    
    # Run tests
    test_s6_installation
    test_s6_service_definitions
    test_s6_log_pipeline
    test_s6_bundles
    test_s6_runtime
    test_service_dependencies
    test_log_management
    
    # Print results
    echo "================================"
    log_info "S6-overlay Test Results:"
    echo -e "${GREEN}Passed: ${TESTS_PASSED}${NC}"
    echo -e "${RED}Failed: ${TESTS_FAILED}${NC}"
    
    if [ $TESTS_FAILED -eq 0 ]; then
        log_success "All s6-overlay tests passed!"
        exit 0
    else
        log_error "Some s6-overlay tests failed!"
        exit 1
    fi
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi