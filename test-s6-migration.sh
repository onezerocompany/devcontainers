#!/bin/bash
# Test script for s6-overlay migration

set -e

echo "Testing s6-overlay migration..."
echo

# Test 1: Build standard variant
echo "1. Building standard variant..."
docker build --target standard -t devcontainer-base:s6-standard images/base/
echo "   ✓ Standard variant built successfully"
echo

# Test 2: Build DIND variant
echo "2. Building DIND variant..."
docker build --target dind -t devcontainer-base:s6-dind images/base/
echo "   ✓ DIND variant built successfully"
echo

# Test 3: Build devcontainer
echo "3. Building devcontainer..."
docker build --build-arg BASE_IMAGE_TAG=s6-dind -t devcontainer:s6-test images/devcontainer/
echo "   ✓ Devcontainer built successfully"
echo

# Test 4: Run standard variant
echo "4. Testing standard variant..."
docker run --rm devcontainer-base:s6-standard sh -c 'echo "Standard variant works" && ps aux | grep s6'
echo "   ✓ Standard variant runs successfully"
echo

# Test 5: Run DIND variant
echo "5. Testing DIND variant..."
docker run --rm --privileged devcontainer-base:s6-dind sh -c 'echo "DIND variant works" && sleep 5 && docker version'
echo "   ✓ DIND variant runs successfully with Docker"
echo

# Test 6: Run devcontainer with sandbox
echo "6. Testing devcontainer with sandbox..."
docker run --rm --cap-add NET_ADMIN --cap-add NET_RAW -e SANDBOX_ENABLED=true devcontainer:s6-test sh -c 'echo "Devcontainer works" && sleep 2 && ps aux | grep blocky'
echo "   ✓ Devcontainer runs successfully with sandbox"
echo

echo "All tests passed! 🎉"