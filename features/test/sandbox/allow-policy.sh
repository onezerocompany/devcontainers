#!/bin/bash
# Test allow policy scenario with blocked domains (pure dnsmasq-based)
set -e

source dev-container-features-test-lib

echo "Testing allow policy configuration (pure dnsmasq-based)..."

# Test that default policy is allow
check "default-policy-allow" grep -q 'DEFAULT_POLICY="allow"' /etc/sandbox/config

# Test that blocked domains are configured
check "example-wildcard-blocked" grep -q "*.example.com" /etc/sandbox/config
check "badsite-blocked" grep -q "badsite.com" /etc/sandbox/config

# Verify dnsmasq configuration generation script exists and handles wildcards
check "dnsmasq-config-script-exists" test -x /usr/local/share/sandbox/generate-dnsmasq-config.sh
check "wildcard-blocking-support" bash -c '
    grep -qE "if \[\[.*domain.*==.*\*\.\*.*\]\]" /usr/local/share/sandbox/generate-dnsmasq-config.sh
'

# Test that dnsmasq setup script exists
check "dnsmasq-setup-script-exists" test -x /usr/local/share/sandbox/setup-dnsmasq.sh

# Test that dnsmasq blocking function exists
check "dnsmasq-blocking-function" grep -q "add_blocked_domain()" /usr/local/share/sandbox/generate-dnsmasq-config.sh

# Test that dnsmasq directory exists
check "dnsmasq-config-dir" test -d /etc/dnsmasq.d

# Test that dnsmasq binary is available
check "dnsmasq-binary-available" command -v dnsmasq

# Test environment variable is set
check "sandbox-env-var" [ "$SANDBOX_NETWORK_FILTER" = "enabled" ]

echo "Allow policy test passed (pure dnsmasq-based)"
reportResults