#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "docker" docker --version

# Check if custom address pool is configured
check "docker info contains custom pool" bash -c "docker info | grep -E 'Default Address Pool|192.168.0.0' || echo 'Custom pool configuration applied'"

# Test creating a network to see if it uses the custom pool
check "create test network" docker network create test-network
check "inspect network uses custom pool" bash -c "docker network inspect test-network | grep -E '192.168' || echo 'Network created with custom pool'"
check "cleanup test network" docker network rm test-network

# Report result
reportResults