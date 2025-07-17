#!/bin/bash
# Test script for runner image - runs inside the container

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
    ((TESTS_PASSED++))
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((TESTS_FAILED++))
}

test_command() {
    local description="$1"
    local command="$2"
    local expected_exit_code="${3:-0}"
    
    if eval "$command" >/dev/null 2>&1; then
        if [ $? -eq $expected_exit_code ]; then
            log_success "$description"
            return 0
        fi
    fi
    
    log_error "$description"
    return 1
}

# Test 1: Base image functionality (inherited)
test_base_functionality() {
    log_info "Testing base image functionality..."
    
    # Test mise is available
    test_command "Mise is installed" "command -v mise"
    test_command "Starship is available" "command -v starship"
    
    # Test basic tools
    test_command "Git is available" "command -v git"
    test_command "Curl is available" "command -v curl"
    test_command "JQ is available" "command -v jq"
}

# Test 2: Runner user setup
test_runner_user() {
    log_info "Testing runner user setup..."
    
    # Test runner user exists
    test_command "Current user is 'runner'" "[ \"\$(whoami)\" = \"runner\" ]"
    test_command "Runner user has UID 1001" "[ \"\$(id -u)\" = \"1001\" ]"
    test_command "Runner user has sudo privileges" "sudo -l | grep -q 'NOPASSWD:ALL'"
    
    # Test runner is in docker group
    test_command "Runner user is in docker group" "groups | grep -q docker"
    
    # Test home directory
    test_command "Home directory is /home/runner" "[ \"\$HOME\" = \"/home/runner\" ]"
    test_command "Home directory exists and is owned by runner" "[ -d \$HOME ] && [ -O \$HOME ]"
}

# Test 3: GitHub Actions runner installation
test_actions_runner() {
    log_info "Testing GitHub Actions runner installation..."
    
    # Test runner files exist
    test_command "Actions runner directory exists" "[ -d /home/runner ]"
    test_command "Runner script exists" "[ -f /home/runner/run.sh ]"
    test_command "Runner script is executable" "[ -x /home/runner/run.sh ]"
    
    # Test runner configuration files
    test_command "Runner config script exists" "[ -f /home/runner/config.sh ]"
    test_command "Runner config script is executable" "[ -x /home/runner/config.sh ]"
    
    # Test runner version file exists
    if [ -f /actions-runner/latest-runner-version ]; then
        log_success "Runner version file exists"
        ((TESTS_PASSED++))
        RUNNER_VERSION=$(cat /actions-runner/latest-runner-version 2>/dev/null || echo "unknown")
        log_info "Runner version: $RUNNER_VERSION"
    else
        log_info "Runner version file not found"
    fi
}

# Test 4: Docker client installation
test_docker_client() {
    log_info "Testing Docker client installation..."
    
    # Test Docker client is available
    test_command "Docker client is available" "command -v docker"
    test_command "Docker client is executable" "[ -x /usr/bin/docker ]"
    
    # Test Docker buildx plugin
    test_command "Docker buildx plugin exists" "[ -f /usr/local/lib/docker/cli-plugins/docker-buildx ]"
    test_command "Docker buildx plugin is executable" "[ -x /usr/local/lib/docker/cli-plugins/docker-buildx ]"
    
    # Test Docker version (client only, daemon may not be running)
    if docker version --client >/dev/null 2>&1; then
        log_success "Docker client version check works"
        ((TESTS_PASSED++))
    else
        log_error "Docker client version check failed"
        ((TESTS_FAILED++))
    fi
}

# Test 5: Container hooks
test_container_hooks() {
    log_info "Testing container hooks..."
    
    # Test hooks directory exists
    test_command "Container hooks directory exists" "[ -d /home/runner/k8s ]"
    
    # Check for hook files (they should exist after installation)
    if [ -d /home/runner/k8s ]; then
        # List some common hook files that should exist
        HOOK_FILES=$(find /home/runner/k8s -name "*.sh" 2>/dev/null | wc -l)
        if [ "$HOOK_FILES" -gt 0 ]; then
            log_success "Container hook scripts found ($HOOK_FILES files)"
            ((TESTS_PASSED++))
        else
            log_info "No container hook scripts found"
        fi
    fi
}

# Test 6: Environment variables
test_environment() {
    log_info "Testing environment variables..."
    
    # Test runner-specific environment variables
    test_command "RUNNER_MANUALLY_TRAP_SIG is set" "[ \"\$RUNNER_MANUALLY_TRAP_SIG\" = \"1\" ]"
    test_command "ACTIONS_RUNNER_PRINT_LOG_TO_STDOUT is set" "[ \"\$ACTIONS_RUNNER_PRINT_LOG_TO_STDOUT\" = \"1\" ]"
    test_command "ImageOS is set" "[ \"\$ImageOS\" = \"ubuntu22\" ]"
    
    # Test PATH includes expected directories
    test_command "PATH includes /usr/bin" "echo \$PATH | grep -q '/usr/bin'"
    
    # Test standard environment variables
    test_command "HOME is set correctly" "[ \"\$HOME\" = \"/home/runner\" ]"
}

# Test 7: Runner entrypoint
test_runner_entrypoint() {
    log_info "Testing runner entrypoint..."
    
    # Test runner entrypoint exists
    test_command "Runner entrypoint exists" "[ -f /usr/local/bin/runner-entrypoint ]"
    test_command "Runner entrypoint is executable" "[ -x /usr/local/bin/runner-entrypoint ]"
    
    # Test sandbox initialization is available (if it exists)
    if [ -x "/usr/local/bin/init-sandbox" ]; then
        log_success "Sandbox initialization script available"
        ((TESTS_PASSED++))
    else
        log_info "Sandbox initialization script not available (normal for runner image)"
    fi
}

# Test 8: File permissions and ownership
test_permissions() {
    log_info "Testing file permissions and ownership..."
    
    # Test runner owns its home directory
    test_command "Runner owns home directory" "[ -O \$HOME ]"
    
    # Test runner can write to home directory
    test_command "Runner can write to home directory" "touch \$HOME/.test_write && rm \$HOME/.test_write"
    
    # Test runner can use sudo
    test_command "Runner can use sudo" "sudo whoami | grep -q root"
    
    # Test docker group has correct permissions
    test_command "Docker group exists" "getent group docker"
}

# Test 9: Actions runner dependencies
test_runner_dependencies() {
    log_info "Testing Actions runner dependencies..."
    
    # Test .NET is available (GitHub Actions runner dependency)
    if command -v dotnet >/dev/null 2>&1; then
        log_success ".NET runtime is available"
        ((TESTS_PASSED++))
    else
        log_info ".NET runtime not available (may be included in runner package)"
    fi
    
    # Test required system packages
    local packages=("tar" "gzip" "unzip")
    
    for pkg in "${packages[@]}"; do
        test_command "Package '$pkg' is available" "command -v $pkg"
    done
}

# Test 10: Docker socket access
test_docker_socket() {
    log_info "Testing Docker socket access..."
    
    # Test Docker socket exists (may not be present in test environment)
    if [ -S /var/run/docker.sock ]; then
        log_success "Docker socket exists"
        ((TESTS_PASSED++))
        
        # Test runner can access Docker socket
        test_command "Runner can access Docker socket" "[ -r /var/run/docker.sock ]"
        
        # Test Docker daemon is accessible
        if docker version >/dev/null 2>&1; then
            log_success "Docker daemon is accessible"
            ((TESTS_PASSED++))
        else
            log_info "Docker daemon not accessible (normal if daemon not running)"
        fi
    else
        log_info "Docker socket not present (normal in test environment)"
    fi
}

# Main test execution
main() {
    log_info "Starting runner image tests..."
    echo "=================================="
    
    # Run tests
    test_base_functionality
    test_runner_user
    test_actions_runner
    test_docker_client
    test_container_hooks
    test_environment
    test_runner_entrypoint
    test_permissions
    test_runner_dependencies
    test_docker_socket
    
    # Print results
    echo "=================================="
    log_info "Test Results:"
    echo -e "${GREEN}Passed: ${TESTS_PASSED}${NC}"
    echo -e "${RED}Failed: ${TESTS_FAILED}${NC}"
    
    if [ $TESTS_FAILED -eq 0 ]; then
        log_success "All tests passed!"
        exit 0
    else
        log_error "Some tests failed!"
        exit 1
    fi
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi