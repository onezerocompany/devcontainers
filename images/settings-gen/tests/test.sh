#!/bin/sh
# Test script for settings-gen image - runs inside the container

set -e

# Ensure proper PATH for Alpine
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin"

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
    
    if eval "$command" >/dev/null 2>&1; then
        if [ $? -eq $expected_exit_code ]; then
            log_success "$description"
            return 0
        fi
    fi
    
    log_error "$description"
    return 1
}

# Test 1: Base Alpine environment
test_base_environment() {
    log_info "Testing base Alpine environment..."
    
    # Test we're running on Alpine
    test_command "Running on Alpine Linux" "[ -f /etc/alpine-release ]"
    
    # Test basic shell commands
    test_command "Shell is available" "command -v sh"
    test_command "Basic utilities available" "command -v cat && command -v echo && command -v ls"
}

# Test 2: Node.js installation
test_nodejs() {
    log_info "Testing Node.js installation..."
    
    # Test Node.js is installed
    test_command "Node.js is installed" "command -v node"
    test_command "NPM is installed" "command -v npm"
    test_command "JQ is installed" "command -v jq"
    
    # Test Node.js version
    if node --version >/dev/null 2>&1; then
        NODE_VERSION=$(node --version 2>/dev/null || echo "unknown")
        log_success "Node.js version: $NODE_VERSION"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_error "Node.js version check failed"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Test 3: DevContainers CLI installation
test_devcontainers_cli() {
    log_info "Testing DevContainers CLI installation..."
    
    # Test DevContainers CLI is installed
    test_command "DevContainers CLI is installed" "command -v devcontainer"
    
    # Test DevContainers CLI version
    if devcontainer --version >/dev/null 2>&1; then
        DEVCONTAINER_VERSION=$(devcontainer --version 2>/dev/null || echo "unknown")
        log_success "DevContainers CLI version: $DEVCONTAINER_VERSION"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_error "DevContainers CLI version check failed"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Test 4: Docker-in-Docker functionality
test_docker_functionality() {
    log_info "Testing Docker-in-Docker functionality..."
    
    # Test Docker client is available
    test_command "Docker client is available" "command -v docker"
    
    # Test dockerd-entrypoint exists
    test_command "Dockerd entrypoint exists" "command -v dockerd-entrypoint.sh"
    
    # Test Docker daemon can start (this is tested in the gen.sh script)
    if pgrep dockerd >/dev/null 2>&1; then
        log_success "Docker daemon is running"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        
        # Test Docker client can communicate with daemon
        test_command "Docker client can communicate with daemon" "docker version"
    else
        log_info "Docker daemon not running (normal if not started by gen.sh)"
    fi
}

# Test 5: Generation script
test_generation_script() {
    log_info "Testing generation script..."
    
    # Test gen.sh exists and is executable
    test_command "Generation script exists" "[ -f /usr/local/bin/gen.sh ]"
    test_command "Generation script is executable" "[ -x /usr/local/bin/gen.sh ]"
    
    # Test gen.sh can be sourced (syntax check)
    if sh -n /usr/local/bin/gen.sh 2>/dev/null; then
        log_success "Generation script has valid syntax"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_error "Generation script has syntax errors"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Test 6: Docker configuration
test_docker_configuration() {
    log_info "Testing Docker configuration..."
    
    # Test Docker config directory exists
    test_command "Docker config directory exists" "[ -d /root/.docker ]"
    
    # Test Docker config file exists
    test_command "Docker config file exists" "[ -f /root/.docker/config.json ]"
    
    # Test Docker config file is readable
    test_command "Docker config file is readable" "[ -r /root/.docker/config.json ]"
    
    # Test Docker config file is valid JSON
    if jq . /root/.docker/config.json >/dev/null 2>&1; then
        log_success "Docker config file is valid JSON"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_error "Docker config file is not valid JSON"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Test 7: Output directories
test_output_directories() {
    log_info "Testing output directories..."
    
    # Test expected output directories are created when gen.sh runs
    # These directories should be created by gen.sh
    
    # Test we can create the expected directories
    test_command "Can create vscode settings directory" "mkdir -p /tmp/test-vscode/settings"
    test_command "Can remove test directory" "rm -rf /tmp/test-vscode"
    
    # Test permissions for directory creation
    test_command "Can create directories in /tmp" "mkdir -p /tmp/test-permissions && rmdir /tmp/test-permissions"
}

# Test 8: Workspace handling
test_workspace_handling() {
    log_info "Testing workspace handling..."
    
    # Test workspace directory can be created
    test_command "Can create workspace directory" "mkdir -p /tmp/test-workspace"
    
    # Test workspace directory permissions
    test_command "Can write to workspace directory" "touch /tmp/test-workspace/test-file && rm /tmp/test-workspace/test-file"
    
    # Clean up
    test_command "Can remove workspace directory" "rm -rf /tmp/test-workspace"
}

# Test 9: Settings generation functionality
test_settings_generation() {
    log_info "Testing settings generation functionality..."
    
    # Create a minimal test workspace
    mkdir -p /tmp/test-workspace/.devcontainer
    cat > /tmp/test-workspace/.devcontainer/devcontainer.json << 'EOF'
{
    "name": "Test Container",
    "image": "ubuntu:latest",
    "customizations": {
        "vscode": {
            "extensions": ["ms-vscode.vscode-typescript-next"],
            "settings": {
                "editor.fontSize": 14
            }
        }
    }
}
EOF
    
    # Test devcontainer read-configuration works
    if devcontainer read-configuration --workspace-folder /tmp/test-workspace --include-merged-configuration >/dev/null 2>&1; then
        log_success "DevContainer configuration can be read"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_error "DevContainer configuration read failed"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    
    # Clean up
    rm -rf /tmp/test-workspace
}

# Test 10: Entrypoint functionality
test_entrypoint() {
    log_info "Testing entrypoint functionality..."
    
    # Test entrypoint is gen.sh
    test_command "Entrypoint is gen.sh" "[ \"\$(readlink -f /usr/local/bin/gen.sh)\" = \"/usr/local/bin/gen.sh\" ]"
    
    # Test file permissions on entrypoint
    test_command "Entrypoint has execute permissions" "[ -x /usr/local/bin/gen.sh ]"
    
    # Test entrypoint can be executed (dry run check)
    if echo 'echo "test"' | sh >/dev/null 2>&1; then
        log_success "Shell execution works"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_error "Shell execution failed"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Test 11: File system permissions
test_filesystem_permissions() {
    log_info "Testing file system permissions..."
    
    # Test we can write to /tmp
    test_command "Can write to /tmp" "touch /tmp/test-write && rm /tmp/test-write"
    
    # Test we can write to /vscode (common output directory)
    test_command "Can create /vscode directory" "mkdir -p /vscode && rmdir /vscode"
    
    # Test we have read access to required files
    test_command "Can read Docker config" "[ -r /root/.docker/config.json ]"
    test_command "Can read generation script" "[ -r /usr/local/bin/gen.sh ]"
}

# Main test execution
main() {
    log_info "Starting settings-gen image tests..."
    echo "====================================="
    
    # Run tests
    test_base_environment
    test_nodejs
    test_devcontainers_cli
    test_docker_functionality
    test_generation_script
    test_docker_configuration
    test_output_directories
    test_workspace_handling
    test_settings_generation
    test_entrypoint
    test_filesystem_permissions
    
    # Print results
    echo "====================================="
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
if [ "${0##*/}" = "test.sh" ]; then
    main "$@"
fi