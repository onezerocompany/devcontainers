#!/bin/bash

set -e

source dev-container-features-test-lib

# Default scenario test - verify docker-in-docker works
check "docker command exists" command -v docker
check "docker version" docker version
check "docker info" docker info

# Report results
reportResults