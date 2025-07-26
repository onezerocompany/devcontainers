#!/bin/bash
# Test logging disabled scenario
set -e

source dev-container-features-test-lib

echo "Testing logging disabled configuration..."

# Test that logging is disabled in config
check "logging-disabled" grep -q 'LOG_BLOCKED="false"' /etc/sandbox/config

# Test that iptables logging rules are not present
check "no-log-rules" bash -c '! iptables -t filter -L SANDBOX_OUTPUT -n | grep -q "LOG"'

# Test that basic filtering still works
check "sandbox-chain-exists" iptables -t filter -L SANDBOX_OUTPUT >/dev/null 2>&1
check "sandbox-chain-attached" iptables -t filter -L OUTPUT | grep -q "SANDBOX_OUTPUT"

# Test that configuration is otherwise normal
check "default-policy" grep -q 'DEFAULT_POLICY=' /etc/sandbox/config
check "docker-networks" grep -q 'ALLOW_DOCKER_NETWORKS=' /etc/sandbox/config
check "localhost" grep -q 'ALLOW_LOCALHOST=' /etc/sandbox/config

# Test environment variable is set
check "sandbox-env-var" [ "$SANDBOX_NETWORK_FILTER" = "enabled" ]

# Test that DNS filtering is still active
check "dnsmasq-config-exists" test -f /etc/dnsmasq.d/sandbox.conf

echo "Logging disabled test passed"
reportResults