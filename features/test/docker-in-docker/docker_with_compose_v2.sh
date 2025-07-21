#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "docker" docker --version
check "docker compose" bash -c "docker compose version | grep -E 'v2\.[0-9]+\.[0-9]+'"
check "docker-compose" bash -c "which docker-compose"
check "compose is v2" bash -c "docker-compose --version | grep -E 'v2\.[0-9]+\.[0-9]+'"

# Test docker compose functionality
check "docker compose config" bash -c "echo 'version: \"3\"' > /tmp/docker-compose.yml && docker compose -f /tmp/docker-compose.yml config"

# Report result
reportResults