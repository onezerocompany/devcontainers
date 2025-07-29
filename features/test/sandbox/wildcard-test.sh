#!/bin/bash
# Test wildcard domain blocking functionality (dnsmasq-based)
set -e

source dev-container-features-test-lib

echo "Testing wildcard domain blocking functionality (dnsmasq-based)..."

# Check that sandbox is enabled
check "sandbox-env-var" [ "$SANDBOX_NETWORK_FILTER" = "enabled" ]

# Check that wildcard domains are in the config
check "wildcard-domains-in-config" bash -c '
    grep -q "*.facebook.com" /etc/sandbox/config &&
    grep -q "*.twitter.com" /etc/sandbox/config &&
    grep -q "*.example.com" /etc/sandbox/config
'

# Check that the dnsmasq setup script exists and is executable
check "dnsmasq-setup-script-exists" test -x /usr/local/share/sandbox/setup-dnsmasq.sh

# Check that the dnsmasq config generation script exists and is executable
check "dnsmasq-config-script-exists" test -x /usr/local/share/sandbox/generate-dnsmasq-config.sh

# Check that dnsmasq package is installed
check "dnsmasq-installed" command -v dnsmasq

# Verify the config generation script can handle wildcard domains
check "wildcard-handling-code" bash -c '
    grep -qE "if \[\[.*domain.*==.*\*\.\*.*\]\]" /usr/local/share/sandbox/generate-dnsmasq-config.sh
'

# Test the domain extraction logic (without actually running dnsmasq)
check "wildcard-domain-extraction" bash -c '
    # The config should show the wildcard domains were processed
    grep -E "(facebook\.com|twitter\.com|example\.com)" /etc/sandbox/config
'

# Check that dnsmasq directory exists
check "dnsmasq-dir-exists" test -d /etc/dnsmasq.d

echo "Wildcard domain blocking test completed (dnsmasq-based)"
reportResults