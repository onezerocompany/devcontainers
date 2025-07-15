#!/bin/bash
# Test script to verify sandbox functionality across all images

set -e

echo "=== Testing Sandbox Setup Across All Images ==="

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test function
test_image() {
    local image_name=$1
    local tag=$2
    local test_name=$3
    
    echo -e "\n${YELLOW}Testing ${test_name}...${NC}"
    
    # Test 1: Sandbox disabled (default)
    echo "Test 1: Sandbox disabled (default)"
    docker run --rm ${image_name}:${tag} bash -c "
        if [ -f /usr/local/bin/init-sandbox ]; then
            echo '✓ Sandbox script exists'
        else
            echo '✗ Sandbox script missing'
            exit 1
        fi
        
        if [ -f /var/lib/devcontainer-sandbox/enabled ] && [ \$(cat /var/lib/devcontainer-sandbox/enabled) = 'true' ]; then
            echo '✗ Sandbox should not be enabled by default'
            exit 1
        else
            echo '✓ Sandbox is disabled by default'
        fi
    "
    
    # Test 2: Sandbox enabled
    echo "Test 2: Sandbox enabled with environment variable"
    docker run --rm -e DEVCONTAINER_SANDBOX_ENABLED=true ${image_name}:${tag} bash -c "
        # Wait for initialization
        sleep 2
        
        if [ -f /var/lib/devcontainer-sandbox/enabled ] && [ \$(cat /var/lib/devcontainer-sandbox/enabled) = 'true' ]; then
            echo '✓ Sandbox is enabled'
        else
            echo '✗ Sandbox should be enabled'
            exit 1
        fi
    "
    
    # Test 3: Firewall functionality (when enabled)
    echo "Test 3: Sandbox with firewall enabled"
    docker run --rm --cap-add NET_ADMIN \
        -e DEVCONTAINER_SANDBOX_ENABLED=true \
        -e DEVCONTAINER_SANDBOX_FIREWALL=true \
        -e ENABLE_SANDBOX_FIREWALL=true \
        ${image_name}:${tag} bash -c "
        # Wait for initialization
        sleep 3
        
        if [ -f /var/lib/devcontainer-sandbox/firewall ] && [ \$(cat /var/lib/devcontainer-sandbox/firewall) = 'true' ]; then
            echo '✓ Firewall configuration saved'
        else
            echo '✗ Firewall configuration not saved'
            exit 1
        fi
        
        # Check if firewall script exists
        if [ -f /usr/local/share/sandbox/init-firewall.sh ]; then
            echo '✓ Firewall script exists'
        else
            echo '✗ Firewall script missing'
            exit 1
        fi
    "
    
    echo -e "${GREEN}✓ ${test_name} passed all tests${NC}"
}

# Build base images first
echo "Building base images..."
cd /Users/luca/Projects/devcontainers/images/base
docker build -t test-base:standard --target standard .
docker build -t test-base:dind --target dind .

# Build devcontainer images
echo "Building devcontainer images..."
cd /Users/luca/Projects/devcontainers/images/devcontainer
docker build -t test-devcontainer:standard --build-arg BASE_IMAGE_REGISTRY=test --build-arg BASE_IMAGE_NAME=base --build-arg BASE_IMAGE_TAG=standard --build-arg DIND=false .
docker build -t test-devcontainer:dind --build-arg BASE_IMAGE_REGISTRY=test --build-arg BASE_IMAGE_NAME=base --build-arg BASE_IMAGE_TAG=dind --build-arg DIND=true .

# Build runner image
echo "Building runner image..."
cd /Users/luca/Projects/devcontainers/images/runner
docker build -t test-runner:latest .

# Run tests
test_image "test-base" "standard" "Base Standard Image"
test_image "test-base" "dind" "Base DIND Image"
test_image "test-devcontainer" "standard" "Devcontainer Standard Image"
test_image "test-devcontainer" "dind" "Devcontainer DIND Image"
test_image "test-runner" "latest" "Runner Image"

echo -e "\n${GREEN}=== All tests passed! ===${NC}"
echo "Sandbox functionality is now available in all images."
echo ""
echo "To enable sandbox in a container, use these environment variables:"
echo "  DEVCONTAINER_SANDBOX_ENABLED=true    # Enable sandbox mode"
echo "  DEVCONTAINER_SANDBOX_FIREWALL=true   # Enable firewall (requires NET_ADMIN capability)"
echo "  DEVCONTAINER_SANDBOX_ALLOWED_DOMAINS=example.com,another.com  # Additional allowed domains"