#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Feature specific tests
check "version" docker --version
check "docker-init-exists" bash -c "ls /usr/local/share/docker-init.sh"
check "docker-ps" bash -c "docker ps"
check "log-exists" bash -c "ls /tmp/dockerd.log"
check "log-for-completion" bash -c "cat /tmp/dockerd.log | grep 'Daemon has completed initialization'"
check "log-contents" bash -c "cat /tmp/dockerd.log | grep 'API listen on /var/run/docker.sock'"

# Check if Docker is actually running
check "docker-info" docker info

# Check Docker Compose v2
check "docker-compose-v2" bash -c "docker compose version"

# Check Docker Buildx
check "docker-buildx" bash -c "docker buildx version"

# Test pulling an image
check "docker-pull" docker pull hello-world

# Test running a container
check "docker-run" docker run --rm hello-world

# Report result
reportResults