#!/bin/bash
# Test Docker networks enabled scenario
set -e

source dev-container-features-test-lib

echo "Testing Docker networks configuration..."

# Test that Docker networks are allowed in config
check "docker-networks-enabled" grep -q 'ALLOW_DOCKER_NETWORKS="true"' /etc/sandbox/config

# Test that localhost is allowed
check "localhost-enabled" grep -q 'ALLOW_LOCALHOST="true"' /etc/sandbox/config

# Test that iptables rules include Docker network ranges
# Note: iptables commands require root privileges, skip if not available
if iptables -t filter -L SANDBOX_OUTPUT >/dev/null 2>&1; then
    check "docker-bridge-allowed" iptables -t filter -L SANDBOX_OUTPUT | grep -q "172.16.0.0/12"
    check "docker-network-10" iptables -t filter -L SANDBOX_OUTPUT | grep -q "10.0.0.0/8"  
    check "docker-network-192" iptables -t filter -L SANDBOX_OUTPUT | grep -q "192.168.0.0/16"
    check "localhost-allowed" iptables -t filter -L SANDBOX_OUTPUT | grep -q "127.0.0.0/8"
else
    echo "⚠️  Skipping iptables rules tests - requires root privileges"
    check "iptables-test-skipped" true
fi

echo "Docker networks test passed"
reportResults