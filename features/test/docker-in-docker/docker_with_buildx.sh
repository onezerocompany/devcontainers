#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "docker" docker --version
check "docker-buildx" docker buildx version
check "docker-buildx-path" bash -c "ls -la /usr/libexec/docker/cli-plugins/docker-buildx || ls -la /usr/local/lib/docker/cli-plugins/docker-buildx"

# Test buildx functionality
check "buildx ls" docker buildx ls
check "buildx inspect" docker buildx inspect

# Test creating a builder instance
check "buildx create" bash -c "docker buildx create --name testbuilder && docker buildx rm testbuilder"

# Report result
reportResults