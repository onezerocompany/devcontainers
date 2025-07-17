#!/bin/bash
# Test script for devcontainer image - runs inside the container

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
    
    log_error "$description"
    return 1
}

# Test 1: Base image functionality (inherited)
test_base_functionality() {
    log_info "Testing base image functionality..."
    
    # Test user setup
    test_command "Current user is 'zero'" "[ \"\$(whoami)\" = \"zero\" ]"
    test_command "User has UID 1000" "[ \"\$(id -u)\" = \"1000\" ]"
    test_command "User has sudo privileges" "sudo -l | grep -q 'NOPASSWD: ALL'"
    
    # Test mise is available
    test_command "Mise is installed" "command -v mise"
    test_command "Mise configuration exists" "[ -f \$HOME/.mise.toml ]"
    
    # Test shell setup
    test_command "Zsh is the default shell" "echo \$SHELL | grep -q zsh"
    test_command "Starship is available" "command -v starship"
}

# Test 2: Devcontainer-specific scripts
test_devcontainer_scripts() {
    log_info "Testing devcontainer-specific scripts..."
    
    # Test devcontainer entrypoint
    test_command "Devcontainer entrypoint exists" "[ -f /usr/local/bin/devcontainer-entrypoint ]"
    test_command "Devcontainer entrypoint is executable" "[ -x /usr/local/bin/devcontainer-entrypoint ]"
    
    # Test sandbox initialization script
    test_command "Sandbox init script exists" "[ -f /usr/local/bin/init-sandbox ]"
    test_command "Sandbox init script is executable" "[ -x /usr/local/bin/init-sandbox ]"
    
    # Test post-create hook
    test_command "Post-create hook exists" "[ -f /usr/local/bin/post-create ]"
    test_command "Post-create hook is executable" "[ -x /usr/local/bin/post-create ]"
    
    # Test post-attach hook
    test_command "Post-attach hook exists" "[ -f /usr/local/bin/post-attach ]"
    test_command "Post-attach hook is executable" "[ -x /usr/local/bin/post-attach ]"
}

# Test 3: VSCode integration
test_vscode_integration() {
    log_info "Testing VSCode integration..."
    
    # Test vscode-kit is available
    test_command "VSCode kit is available" "command -v vscode-kit"
    test_command "VSCode kit is executable" "[ -x /usr/local/bin/vscode-kit ]"
    
    # Test devcontainer init completion marker
    if [ -f /tmp/.devcontainer-init-complete ]; then
        log_success "Devcontainer initialization marker exists"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_info "Devcontainer initialization marker not present (normal if not started via devcontainer entrypoint)"
    fi
}

# Test 4: Sandbox functionality
test_sandbox_functionality() {
    log_info "Testing sandbox functionality..."
    
    # Test sandbox state directory
    test_command "Sandbox state directory exists" "[ -d /var/lib/devcontainer-sandbox ]"
    
    # Test sandbox state file exists
    if [ -f /var/lib/devcontainer-sandbox/enabled ]; then
        log_success "Sandbox state file exists"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        
        # Read sandbox state
        SANDBOX_STATE=$(cat /var/lib/devcontainer-sandbox/enabled 2>/dev/null || echo "unknown")
        log_info "Sandbox state: $SANDBOX_STATE"
        
        # Test sandbox domains file (if sandbox is enabled)
        if [ "$SANDBOX_STATE" = "true" ]; then
            test_command "Sandbox domains file exists" "[ -f /var/lib/devcontainer-sandbox/domains ]"
            
            # Test firewall functionality (if available)
            if command -v iptables >/dev/null 2>&1; then
                test_command "Iptables is available" "command -v iptables"
                log_info "Firewall testing requires privileged container"
            else
                log_info "Iptables not available (normal in non-privileged containers)"
            fi
        fi
    else
        log_info "Sandbox state file not present (normal if sandbox not initialized)"
    fi
}

# Test 5: Development environment
test_development_environment() {
    log_info "Testing development environment..."
    
    # Test that development tools are available
    test_command "Git is available" "command -v git"
    test_command "Curl is available" "command -v curl"
    test_command "JQ is available" "command -v jq"
    
    # Test PATH includes local bin
    test_command "Local bin in PATH" "echo \$PATH | grep -q '/home/zero/.local/bin'"
    
    # Test mise activation works
    if [ -f "$HOME/.local/bin/mise" ]; then
        test_command "Mise can be activated" "export PATH=\"/home/zero/.local/bin:\$PATH\" && eval \"\$(/home/zero/.local/bin/mise activate bash --shims)\""
    else
        log_info "Mise not available in expected location"
    fi
}

# Test 6: Container environment detection
test_container_environment() {
    log_info "Testing container environment detection..."
    
    # Test container environment markers
    test_command "Container environment file exists" "[ -f /.dockerenv ]"
    
    # Test common devcontainer environment variables (if set)
    if [ -n "$DEVCONTAINER" ]; then
        log_success "DEVCONTAINER environment variable is set"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_info "DEVCONTAINER environment variable not set (normal if not in VS Code)"
    fi
    
    if [ -n "$REMOTE_CONTAINERS" ]; then
        log_success "REMOTE_CONTAINERS environment variable is set"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_info "REMOTE_CONTAINERS environment variable not set (normal if not in VS Code)"
    fi
}

# Test 7: Shell customizations
test_shell_customizations() {
    log_info "Testing shell customizations..."
    
    # Test starship config exists
    test_command "Starship config exists" "[ -f \$HOME/.config/starship.toml ]"
    
    # Test zsh configuration
    test_command "Zsh config exists" "[ -f \$HOME/.zshrc ]"
    
    # Test shell profile configurations
    if [ -f "$HOME/.zshenv" ]; then
        log_success "Zsh environment file exists"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_info "Zsh environment file not present"
    fi
}

# Test 8: Permissions and security
test_permissions() {
    log_info "Testing permissions and security..."
    
    # Test user can write to home directory
    test_command "User can write to home directory" "touch \$HOME/.test_write && rm \$HOME/.test_write"
    
    # Test user can use sudo
    test_command "User can use sudo" "sudo whoami | grep -q root"
    
    # Test sandbox state files are read-only (security feature)
    if [ -f /var/lib/devcontainer-sandbox/enabled ]; then
        test_command "Sandbox state file is read-only" "[ ! -w /var/lib/devcontainer-sandbox/enabled ]"
    fi
}

# Main test execution
main() {
    log_info "Starting devcontainer image tests..."
    echo "========================================"
    
    # Run tests
    test_base_functionality
    test_devcontainer_scripts
    test_vscode_integration
    test_sandbox_functionality
    test_development_environment
    test_container_environment
    test_shell_customizations
    test_permissions
    
    # Print results
    echo "========================================"
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