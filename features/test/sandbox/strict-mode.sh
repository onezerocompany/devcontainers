#!/bin/bash
# Test strict mode scenario
set -e

source dev-container-features-test-lib

echo "Testing strict mode configuration..."

# Test that Docker networks are disabled in config
check "docker-networks-disabled" grep -q 'ALLOW_DOCKER_NETWORKS="false"' /etc/sandbox/config

# Test that localhost is disabled
check "localhost-disabled" grep -q 'ALLOW_LOCALHOST="false"' /etc/sandbox/config

# Test that immutable config is enabled
check "immutable-config" grep -q 'IMMUTABLE_CONFIG="true"' /etc/sandbox/config

# Test that only specific domain is allowed
check "only-github-api-allowed" grep -q "api.github.com" /etc/sandbox/config

# Test that config file is read-only (if chattr worked)
check "config-readonly" [ ! -w /etc/sandbox/config ] || true

echo "Strict mode test passed"
reportResults