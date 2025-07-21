#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "docker" docker --version
check "moby-cli" bash -c "dpkg -l | grep moby-cli"
check "moby-engine" bash -c "dpkg -l | grep moby-engine"
check "docker info shows moby" bash -c "docker info | grep -i moby"

# Check moby-buildx
check "moby-buildx" bash -c "dpkg-query -W moby-buildx"

# Test docker functionality with moby
check "docker run with moby" docker run --rm hello-world

# Report result
reportResults