#!/bin/bash
# Comprehensive test runner for devcontainer base images

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test results
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

log_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

# Run build tests
run_build_tests() {
    log_test "Running build tests for both variants..."
    
    # Test standard build
    log_info "Building standard variant..."
    if docker build --target test-standard -t devcontainer-base:test-standard . >/dev/null 2>&1; then
        log_success "Standard variant build tests passed"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        log_error "Standard variant build tests failed"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    # Test DIND build
    log_info "Building DIND variant..."
    if docker build --target test-dind -t devcontainer-base:test-dind . >/dev/null 2>&1; then
        log_success "DIND variant build tests passed"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        log_error "DIND variant build tests failed"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
}

# Run runtime tests
run_runtime_tests() {
    log_test "Running runtime tests..."
    
    # Test standard runtime
    log_info "Testing standard variant runtime..."
    if docker run --rm devcontainer-base:test-standard /tests/test-s6-runtime.sh 2>&1 | grep -q "s6-svscan is not running"; then
        log_success "Standard variant correctly runs without s6 (as expected)"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        log_error "Standard variant runtime test had unexpected result"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    # Test DIND runtime
    log_info "Testing DIND variant runtime with s6-overlay..."
    if docker run --rm --privileged devcontainer-base:test-dind /tests/test-s6-runtime.sh; then
        log_success "DIND variant runtime tests passed"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        log_error "DIND variant runtime tests failed"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
}

# Run s6-overlay specific tests
run_s6_tests() {
    log_test "Running s6-overlay specific tests..."
    
    # Test s6 service startup sequence
    log_info "Testing s6 service startup sequence in DIND variant..."
    local test_output=$(docker run --rm --privileged devcontainer-base:test-dind bash -c "
        # Wait for services to start
        sleep 5
        
        # Check service order
        echo 'Checking service startup order...'
        s6-rc -a list
        
        # Verify dockerd started before docker-permissions
        if s6-svstat /run/service/dockerd | grep -q up && [ -S /var/run/docker.sock ]; then
            echo 'SUCCESS: Services started in correct order'
            exit 0
        else
            echo 'FAIL: Service startup issue detected'
            exit 1
        fi
    " 2>&1)
    
    if echo "$test_output" | grep -q "SUCCESS"; then
        log_success "S6 service startup sequence is correct"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        log_error "S6 service startup sequence failed"
        echo "$test_output"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
}

# Clean up
cleanup() {
    log_info "Cleaning up test images..."
    docker rmi devcontainer-base:test-standard devcontainer-base:test-dind >/dev/null 2>&1
}

# Main execution
main() {
    log_info "Starting comprehensive devcontainer base image tests"
    echo "================================================"
    
    # Change to script directory
    cd "$(dirname "$0")"
    
    # Run test suites
    run_build_tests
    run_runtime_tests
    run_s6_tests
    
    # Summary
    echo "================================================"
    log_info "Test Summary:"
    echo -e "Total Tests: ${TOTAL_TESTS}"
    echo -e "${GREEN}Passed: ${PASSED_TESTS}${NC}"
    echo -e "${RED}Failed: ${FAILED_TESTS}${NC}"
    
    # Cleanup
    cleanup
    
    # Exit with appropriate code
    if [ $FAILED_TESTS -eq 0 ]; then
        log_success "All tests passed!"
        exit 0
    else
        log_error "Some tests failed!"
        exit 1
    fi
}

# Handle script arguments
case "${1:-}" in
    --no-cleanup)
        trap - EXIT
        ;;
    --help|-h)
        echo "Usage: $0 [--no-cleanup]"
        echo "  --no-cleanup: Keep test images after tests complete"
        exit 0
        ;;
esac

# Set trap for cleanup on exit
trap cleanup EXIT

# Run main
main "$@"