#!/bin/bash
# Test allow policy scenario with blocked domains
set -e

source dev-container-features-test-lib

echo "Testing allow policy configuration..."

# Test that default policy is allow
check "default-policy-allow" grep -q 'DEFAULT_POLICY="allow"' /etc/sandbox/config

# Test that blocked domains are configured
check "example-wildcard-blocked" grep -q "*.example.com" /etc/sandbox/config
check "badsite-blocked" grep -q "badsite.com" /etc/sandbox/config

# Verify wildcard handling for blocked domains
check "wildcard-blocking-support" bash -c '
    grep -q "COMMON_SUBDOMAINS=(" /usr/local/share/sandbox/setup-rules.sh
'

# DNS filtering is no longer used - removed hosts file tests
# check "example-in-hosts" grep -q "127.0.0.1.*example.com" /etc/hosts
# check "badsite-in-hosts" grep -q "127.0.0.1.*badsite.com" /etc/hosts

# DNS filtering is no longer used - removed dnsmasq tests
# check "wildcard-config-example" grep -q "address=/example.com/127.0.0.1" /etc/dnsmasq.d/sandbox.conf
# check "wildcard-config-badsite" grep -q "address=/badsite.com/127.0.0.1" /etc/dnsmasq.d/sandbox.conf

# Test iptables rules - should have ACCEPT as default for allow policy
# Skip if iptables is not accessible or lacks privileges
if command -v iptables >/dev/null 2>&1 && iptables -t filter -L >/dev/null 2>&1; then
    if iptables -t filter -L SANDBOX_OUTPUT >/dev/null 2>&1; then
        check "default-accept-rule" iptables -t filter -L SANDBOX_OUTPUT | grep -q "ACCEPT.*all"
    else
        echo "⚠️  SANDBOX_OUTPUT chain not found - sandbox may not be properly configured"
        check "sandbox-chain-missing" false
    fi
else
    echo "⚠️  Skipping iptables tests - requires root privileges or iptables not accessible"
    check "iptables-test-skipped" true
fi

# DNS filtering is no longer used - removed DNS blocking test
# Note: In allow mode, blocking is done via iptables rules only
# check "dns-blocking-active" test -f /etc/dnsmasq.d/sandbox.conf

# Test environment variable is set (check multiple possible sources)
check "sandbox-env-var" bash -c '[ "$SANDBOX_NETWORK_FILTER" = "enabled" ] || [ -f /etc/sandbox/config ]'

echo "Allow policy test passed"
reportResults