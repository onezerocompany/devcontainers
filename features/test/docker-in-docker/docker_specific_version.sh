#!/bin/bash

set -e

source dev-container-features-test-lib

# Specific version scenario test - verify docker-in-docker works with specific version
check "docker command exists" command -v docker
check "docker version" docker version
check "docker info" docker info

# Report results
reportResults