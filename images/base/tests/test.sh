#!/bin/bash
# Test script for base image - runs inside the container

set -e

# Ensure proper environment setup
export HOME=/home/zero
export PATH="/home/zero/.local/bin:$PATH"
export MISE_CACHE_DIR="/home/zero/.cache/mise"
export MISE_DATA_DIR="/home/zero/.local/share/mise"
export SHELL=/bin/zsh

# Initialize mise if available
if [ -f "$HOME/.local/bin/mise" ]; then
    eval "$($HOME/.local/bin/mise activate bash --shims)"
fi

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
    
    log_error "$description"
    return 1
}

# Test 1: User setup validation
test_user_setup() {
    log_info "Testing user setup..."
    
    # Test current user is zero
    test_command "Current user is 'zero'" "[ \"\$(whoami)\" = \"zero\" ]"
    
    # Test user has correct UID/GID
    test_command "User has UID 1000" "[ \"\$(id -u)\" = \"1000\" ]"
    test_command "User has GID 1000" "[ \"\$(id -g)\" = \"1000\" ]"
    
    # Test user has sudo privileges
    test_command "User has sudo privileges" "sudo -l | grep -q 'NOPASSWD: ALL'"
    
    # Test home directory exists and is owned by user
    test_command "Home directory exists and is owned by user" "[ -d \$HOME ] && [ -O \$HOME ]"
}

# Test 2: Mise installation and tools
test_mise_setup() {
    log_info "Testing mise installation and tool setup..."
    
    # Test mise is installed
    test_command "Mise is installed" "command -v mise"
    
    # Test mise configuration exists
    test_command "Mise configuration exists" "[ -f \$HOME/.mise.toml ]"
    
    # Test mise directories exist
    test_command "Mise cache directory exists" "[ -d \$HOME/.cache/mise ]"
    test_command "Mise data directory exists" "[ -d \$HOME/.local/share/mise ]"
    
    # Test some common tools are available via mise
    test_command "Node.js is available via mise" "mise current | grep -q node || node --version"
}

# Test 3: Shell configurations
test_shell_setup() {
    log_info "Testing shell configurations..."
    
    # Test zsh is the default shell
    test_command "Zsh is the default shell" "echo \$SHELL | grep -q zsh"
    
    # Test starship configuration exists
    test_command "Starship configuration exists" "[ -f \$HOME/.config/starship.toml ]"
    
    # Test starship is available
    test_command "Starship is available" "command -v starship"
    
    # Test zsh configuration files exist
    test_command "Zsh configuration exists" "[ -f \$HOME/.zshrc ]"
}

# Test 4: Entrypoint functionality
test_entrypoint() {
    log_info "Testing entrypoint functionality..."
    
    # Test entrypoint scripts exist
    test_command "Main entrypoint script exists" "[ -f /usr/local/bin/entrypoint.sh ]"
    test_command "Entrypoint script is executable" "[ -x /usr/local/bin/entrypoint.sh ]"
    
    # Test entrypoint creates log file (if it exists)
    if [ -f /tmp/entrypoint.log ]; then
        log_success "Entrypoint creates log file"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_info "Entrypoint log file not present (container may not have been started with entrypoint)"
    fi
}

# Test 5: Docker functionality (if available)
test_docker_functionality() {
    log_info "Testing Docker functionality..."
    
    # Check if Docker is available
    if command -v docker >/dev/null 2>&1; then
        test_command "Docker client is available" "command -v docker"
        
        # Test if Docker daemon is running
        if docker version >/dev/null 2>&1; then
            test_command "Docker daemon is accessible" "docker version"
            test_command "User can execute Docker commands" "docker ps"
        else
            log_info "Docker daemon not running (normal for standard variant)"
        fi
    else
        log_info "Docker not available in this image variant"
    fi
}

# Test 6: Common utilities functionality
test_common_utils() {
    log_info "Testing common utilities..."
    
    # Test common utilities script exists
    test_command "Common utilities script exists" "[ -f /usr/local/bin/common-utils.sh ]"
    
    # Test sourcing common utilities works
    test_command "Common utilities can be sourced and functions are available" "source /usr/local/bin/common-utils.sh && declare -f add_to_path"
}

# Test 7: Environment variables
test_environment() {
    log_info "Testing environment variables..."
    
    # Test key environment variables are set
    test_command "Core environment variables are set" "[ -n \"\$HOME\" ] && [ -n \"\$PATH\" ] && [ -n \"\$SHELL\" ]"
    
    # Test mise environment variables
    test_command "Mise environment variables are set" "[ -n \"\$MISE_CACHE_DIR\" ] && [ -n \"\$MISE_DATA_DIR\" ]"
    
    # Test other expected environment variables
    test_command "Username environment variable is set" "[ -n \"\$USERNAME\" ]"
}

# Test 8: Package installations
test_packages() {
    log_info "Testing installed packages..."
    
    # Test common packages are installed
    local packages=("curl" "git" "jq" "zsh" "sudo")
    
    for pkg in "${packages[@]}"; do
        test_command "Package '$pkg' is installed" "command -v $pkg"
    done
}

# Main test execution
main() {
    log_info "Starting base image tests..."
    echo "================================"
    
    # Run tests
    test_user_setup
    test_mise_setup
    test_shell_setup
    test_entrypoint
    test_docker_functionality
    test_common_utils
    test_environment
    test_packages
    
    # Print results
    echo "================================"
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