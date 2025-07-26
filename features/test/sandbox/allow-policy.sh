#!/bin/bash
# Test allow policy scenario with blocked domains
set -e

source dev-container-features-test-lib

echo "Testing allow policy configuration..."

# Test that default policy is allow
check "default-policy-allow" grep -q 'DEFAULT_POLICY="allow"' /etc/sandbox/config

# Test that blocked domains are configured
check "example-blocked" grep -q "example.com" /etc/sandbox/config
check "badsite-blocked" grep -q "badsite.com" /etc/sandbox/config

# Test that blocked domains are in hosts file
check "example-in-hosts" grep -q "127.0.0.1.*example.com" /etc/hosts
check "badsite-in-hosts" grep -q "127.0.0.1.*badsite.com" /etc/hosts

# Test that dnsmasq configuration includes wildcard blocking for blocked domains
check "wildcard-config-example" grep -q "address=/example.com/127.0.0.1" /etc/dnsmasq.d/sandbox.conf
check "wildcard-config-badsite" grep -q "address=/badsite.com/127.0.0.1" /etc/dnsmasq.d/sandbox.conf

# Test iptables rules - should have ACCEPT as default for allow policy
check "default-accept-rule" iptables -t filter -L SANDBOX_OUTPUT | grep -q "ACCEPT.*all"

# Test that specific blocked IPs are rejected
# Note: In allow mode, only specific blocked domains are rejected via DNS
check "dns-blocking-active" test -f /etc/dnsmasq.d/sandbox.conf

# Test environment variable is set
check "sandbox-env-var" [ "$SANDBOX_NETWORK_FILTER" = "enabled" ]

echo "Allow policy test passed"
reportResults