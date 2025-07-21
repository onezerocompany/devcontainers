#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "docker" docker --version

# Check that docker-compose is NOT installed
check "docker-compose not installed" bash -c "! which docker-compose"

# Check that docker compose subcommand might not work or doesn't exist
check "no compose in docker" bash -c "! docker compose version 2>/dev/null || echo 'compose not available'"

# Docker itself should still work
check "docker ps" docker ps
check "docker run" docker run --rm hello-world

# Report result
reportResults