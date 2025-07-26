#!/bin/bash

set -e

source dev-container-features-test-lib

# Disable ip6tables scenario test - verify docker-in-docker works with ip6tables disabled
check "docker command exists" command -v docker
check "docker version" docker version
check "docker info" docker info

# Report results
reportResults