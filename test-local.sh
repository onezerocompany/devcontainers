#!/bin/bash
# Local test script for development

set -e

FAILED_TESTS=0
PASSED_TESTS=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test function
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo -e "\n${YELLOW}Running: ${test_name}${NC}"
    if eval "$test_command"; then
        echo -e "${GREEN}✓ PASSED${NC}"
        ((PASSED_TESTS++))
    else
        echo -e "${RED}✗ FAILED${NC}"
        ((FAILED_TESTS++))
    fi
}

# Check if images exist locally
echo "Checking for local images..."
if ! docker image inspect ghcr.io/onezerocompany/devcontainer:base >/dev/null 2>&1; then
    echo "Image ghcr.io/onezerocompany/devcontainer:base not found locally"
    echo "Run: docker pull ghcr.io/onezerocompany/devcontainer:base"
    exit 1
fi

if ! docker image inspect ghcr.io/onezerocompany/devcontainer:dind >/dev/null 2>&1; then
    echo "Image ghcr.io/onezerocompany/devcontainer:dind not found locally"
    echo "Run: docker pull ghcr.io/onezerocompany/devcontainer:dind"
    exit 1
fi

# Sandbox Tests
echo -e "\n${YELLOW}=== SANDBOX TESTS ===${NC}"

run_test "Sandbox disabled by default" \
    'docker run --rm ghcr.io/onezerocompany/devcontainer:base \
        bash -c "if [ -f /var/lib/devcontainer-sandbox/enabled ]; then exit 1; else exit 0; fi"'

run_test "Sandbox can be enabled" \
    'docker run --rm \
        -e DEVCONTAINER_SANDBOX_ENABLED=true \
        -e DEVCONTAINER_SANDBOX_FIREWALL=false \
        -e DEVCONTAINER=true \
        --cap-add NET_ADMIN \
        ghcr.io/onezerocompany/devcontainer:base \
        bash -c "/usr/local/bin/devcontainer-entrypoint true && \
                 [ -f /var/lib/devcontainer-sandbox/enabled ] && \
                 [ \"\$(cat /var/lib/devcontainer-sandbox/enabled)\" = \"true\" ]"'

run_test "Sandbox is immutable once enabled" \
    'docker run --rm \
        -e DEVCONTAINER_SANDBOX_ENABLED=true \
        -e DEVCONTAINER_SANDBOX_FIREWALL=false \
        -e DEVCONTAINER=true \
        --cap-add NET_ADMIN \
        ghcr.io/onezerocompany/devcontainer:base \
        bash -c "
            /usr/local/bin/devcontainer-entrypoint true
            export DEVCONTAINER_SANDBOX_ENABLED=false
            OUTPUT=\$(/usr/local/bin/devcontainer-entrypoint echo test 2>&1)
            echo \"\$OUTPUT\" | grep -q \"Sandbox mode is enabled (immutable)\""'

# Docker Tests
echo -e "\n${YELLOW}=== DOCKER TESTS ===${NC}"

run_test "Docker CLI installed" \
    'docker run --rm ghcr.io/onezerocompany/devcontainer:dind docker --version'

run_test "Docker Compose v2 installed" \
    'docker run --rm ghcr.io/onezerocompany/devcontainer:dind docker compose version'

run_test "Docker Buildx installed" \
    'docker run --rm ghcr.io/onezerocompany/devcontainer:dind docker buildx version'

run_test "User in docker group" \
    'docker run --rm ghcr.io/onezerocompany/devcontainer:dind \
        bash -c "groups | grep -q docker"'

# Base Image Tests
echo -e "\n${YELLOW}=== BASE IMAGE TESTS ===${NC}"

run_test "VS Code kit installed" \
    'docker run --rm ghcr.io/onezerocompany/devcontainer:base \
        test -f /usr/local/bin/vscode-kit'

run_test "Common utilities installed" \
    'docker run --rm ghcr.io/onezerocompany/devcontainer:base \
        bash -c "command -v fzf && command -v batcat && command -v eza && command -v starship"'

# Summary
echo -e "\n${YELLOW}=== TEST SUMMARY ===${NC}"
echo -e "Passed: ${GREEN}${PASSED_TESTS}${NC}"
echo -e "Failed: ${RED}${FAILED_TESTS}${NC}"

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "\n${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "\n${RED}Some tests failed!${NC}"
    exit 1
fi