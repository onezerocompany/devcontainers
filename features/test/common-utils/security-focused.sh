#!/bin/bash

# Test security-focused configuration
set -e

source dev-container-features-test-lib

# Test that SSH server is NOT installed
check "no-ssh-server" bash -c "! dpkg -l | grep openssh-server"

# Test that SSH client IS installed (from networking bundle)
check "ssh-client" dpkg -l | grep -q openssh-client

# Test that build tools are NOT installed
check "no-build-essential" bash -c "! dpkg -l | grep build-essential"

# Test that containers bundle tools are installed but without k8s tools
check "docker-compose" which docker-compose

# Test that Kubernetes tools are NOT installed
check "no-kubectl" bash -c "! which kubectl"
check "no-k9s" bash -c "! which k9s"
check "no-helm" bash -c "! which helm"

# Test that Podman tools are NOT installed
check "no-podman" bash -c "! which podman"
check "no-buildah" bash -c "! which buildah"

# Test that core networking tools are still available
check "curl" which curl
check "wget" which wget
check "nmap" which nmap

# Report results
reportResults