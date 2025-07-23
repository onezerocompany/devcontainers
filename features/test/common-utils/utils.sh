#!/bin/bash

# Testing utilities for common-utils feature tests
# Provides common functions for testing devcontainer features

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test result tracking
declare -a FAILED_TESTS=()

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Test assertion functions
assert_command_exists() {
    local cmd="$1"
    local test_name="${2:-Command exists: $cmd}"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if command -v "$cmd" >/dev/null 2>&1; then
        log_success "$test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        log_error "$test_name - Command '$cmd' not found"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILED_TESTS+=("$test_name")
        return 1
    fi
}

assert_file_exists() {
    local file="$1"
    local test_name="${2:-File exists: $file}"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if [[ -f "$file" ]]; then
        log_success "$test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        log_error "$test_name - File '$file' not found"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILED_TESTS+=("$test_name")
        return 1
    fi
}

assert_directory_exists() {
    local dir="$1"
    local test_name="${2:-Directory exists: $dir}"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if [[ -d "$dir" ]]; then
        log_success "$test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        log_error "$test_name - Directory '$dir' not found"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILED_TESTS+=("$test_name")
        return 1
    fi
}

assert_file_contains() {
    local file="$1"
    local pattern="$2"
    local test_name="${3:-File contains pattern: $file -> $pattern}"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if [[ -f "$file" ]] && grep -q "$pattern" "$file"; then
        log_success "$test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        log_error "$test_name - Pattern '$pattern' not found in '$file'"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILED_TESTS+=("$test_name")
        return 1
    fi
}

assert_command_output() {
    local cmd="$1"
    local expected_pattern="$2"
    local test_name="${3:-Command output matches: $cmd -> $expected_pattern}"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    local output
    if output=$(eval "$cmd" 2>&1) && echo "$output" | grep -q "$expected_pattern"; then
        log_success "$test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        log_error "$test_name - Command '$cmd' output doesn't match '$expected_pattern'"
        log_error "  Actual output: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILED_TESTS+=("$test_name")
        return 1
    fi
}

assert_command_succeeds() {
    local cmd="$1"
    local test_name="${2:-Command succeeds: $cmd}"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if eval "$cmd" >/dev/null 2>&1; then
        log_success "$test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        log_error "$test_name - Command '$cmd' failed"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILED_TESTS+=("$test_name")
        return 1
    fi
}

assert_command_fails() {
    local cmd="$1"
    local test_name="${2:-Command fails: $cmd}"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if ! eval "$cmd" >/dev/null 2>&1; then
        log_success "$test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        log_error "$test_name - Command '$cmd' should have failed but succeeded"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILED_TESTS+=("$test_name")
        return 1
    fi
}

assert_user_exists() {
    local username="$1"
    local test_name="${2:-User exists: $username}"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if id "$username" >/dev/null 2>&1; then
        log_success "$test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        log_error "$test_name - User '$username' not found"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILED_TESTS+=("$test_name")
        return 1
    fi
}

assert_environment_variable() {
    local var_name="$1"
    local expected_value="$2"
    local test_name="${3:-Environment variable: $var_name = $expected_value}"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    local actual_value="${!var_name}"
    if [[ "$actual_value" == "$expected_value" ]]; then
        log_success "$test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        log_error "$test_name - Expected '$expected_value', got '$actual_value'"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILED_TESTS+=("$test_name")
        return 1
    fi
}

# Test grouping functions
start_test_group() {
    local group_name="$1"
    echo
    log_info "=== Starting test group: $group_name ==="
}

end_test_group() {
    local group_name="$1"
    log_info "=== Finished test group: $group_name ==="
    echo
}

# Test runner functions
run_test() {
    local test_function="$1"
    local test_name="${2:-$test_function}"
    
    log_info "Running test: $test_name"
    
    if "$test_function"; then
        log_success "Test passed: $test_name"
    else
        log_error "Test failed: $test_name"
    fi
}

# Summary functions
print_test_summary() {
    echo
    echo "================================"
    log_info "TEST SUMMARY"
    echo "================================"
    log_info "Tests run: $TESTS_RUN"
    log_success "Tests passed: $TESTS_PASSED"
    
    if [[ $TESTS_FAILED -gt 0 ]]; then
        log_error "Tests failed: $TESTS_FAILED"
        echo
        log_error "Failed tests:"
        for test in "${FAILED_TESTS[@]}"; do
            echo "  - $test"
        done
    fi
    
    echo "================================"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        log_success "ALL TESTS PASSED!"
        return 0
    else
        log_error "SOME TESTS FAILED!"
        return 1
    fi
}

# Function to detect the non-root user
detect_nonroot_user() {
    # Try to find the non-root user using the same logic as common-utils
    local possible_users=("zero" "vscode" "node" "codespace")
    
    # First try the common users
    for user in "${possible_users[@]}"; do
        if id "$user" >/dev/null 2>&1; then
            echo "$user"
            return 0
        fi
    done
    
    # Fallback to UID 1000 user
    local uid_1000_user
    uid_1000_user=$(getent passwd 1000 2>/dev/null | cut -d: -f1 || true)
    if [[ -n "$uid_1000_user" ]]; then
        echo "$uid_1000_user"
        return 0
    fi
    
    # Default fallback
    echo "vscode"
}

# Global variable for detected user
DETECTED_USER=$(detect_nonroot_user)

# Utility functions for common checks
check_shell_tools() {
    start_test_group "Shell Tools"
    
    assert_command_exists "zsh" "Zsh shell is installed"
    assert_command_exists "eza" "Eza (ls replacement) is installed"
    assert_command_exists "bat" "Bat (cat replacement) is installed"
    assert_command_exists "zoxide" "Zoxide (cd replacement) is installed"
    assert_command_exists "starship" "Starship prompt is installed"
    
    end_test_group "Shell Tools"
}

check_container_tools() {
    start_test_group "Container Tools"
    
    assert_command_exists "docker" "Docker CLI is installed"
    assert_command_exists "kubectl" "Kubectl is installed"
    assert_command_exists "helm" "Helm is installed"
    
    end_test_group "Container Tools"
}

check_web_dev_tools() {
    start_test_group "Web Development Tools"
    
    assert_command_exists "bun" "Bun is installed"
    assert_command_exists "deno" "Deno is installed"
    assert_command_exists "node" "Node.js is installed"
    assert_command_exists "npm" "NPM is installed"
    
    end_test_group "Web Development Tools"
}

check_network_tools() {
    start_test_group "Network Tools"
    
    assert_command_exists "curl" "Curl is installed"
    assert_command_exists "wget" "Wget is installed"
    assert_command_exists "dig" "Dig is installed"
    assert_command_exists "nslookup" "Nslookup is installed"
    
    end_test_group "Network Tools"
}

check_utility_tools() {
    start_test_group "Utility Tools"
    
    assert_command_exists "jq" "JQ is installed"
    assert_command_exists "yq" "YQ is installed"
    assert_command_exists "git" "Git is installed"
    assert_command_exists "vim" "Vim is installed"
    
    end_test_group "Utility Tools"
}

check_user_shell_config() {
    local username="$1"
    local home_dir
    
    if [[ "$username" == "root" ]]; then
        home_dir="/root"
    else
        home_dir="/home/$username"
    fi
    
    start_test_group "Shell Configuration for $username"
    
    # Only check if user actually exists
    if id "$username" >/dev/null 2>&1; then
        assert_file_exists "$home_dir/.zshrc" "Zsh config exists for $username"
        assert_file_exists "$home_dir/.config/starship.toml" "Starship config exists for $username"
        
        # Check if shell configs contain expected content
        if [[ -f "$home_dir/.zshrc" ]]; then
            assert_file_contains "$home_dir/.zshrc" "starship" "Zshrc contains starship initialization"
            assert_file_contains "$home_dir/.zshrc" "zoxide" "Zshrc contains zoxide initialization"
        fi
    else
        log_warning "User $username does not exist, skipping shell config check"
    fi
    
    end_test_group "Shell Configuration for $username"
}

# Main test execution wrapper
execute_test_suite() {
    local test_suite_name="$1"
    shift
    local test_functions=("$@")
    
    log_info "Starting test suite: $test_suite_name"
    echo "========================================"
    
    for test_func in "${test_functions[@]}"; do
        if declare -f "$test_func" >/dev/null; then
            "$test_func"
        else
            log_error "Test function '$test_func' not found"
            TESTS_FAILED=$((TESTS_FAILED + 1))
            FAILED_TESTS+=("$test_func")
        fi
    done
    
    print_test_summary
}