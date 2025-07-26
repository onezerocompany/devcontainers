#!/bin/bash
# Test wildcard domain blocking functionality
set -e

source dev-container-features-test-lib

echo "Testing wildcard domain blocking functionality..."

# Check that sandbox is enabled
check "sandbox-env-var" [ "$SANDBOX_NETWORK_FILTER" = "enabled" ]

# Check that wildcard domains are in the config
check "wildcard-domains-in-config" bash -c '
    grep -q "*.facebook.com" /etc/sandbox/config &&
    grep -q "*.twitter.com" /etc/sandbox/config &&
    grep -q "*.example.com" /etc/sandbox/config
'

# Check that the setup script exists and is executable
check "setup-script-exists" test -x /usr/local/share/sandbox/setup-rules.sh

# Check that common subdomains array is defined in the setup script
check "common-subdomains-defined" bash -c '
    grep -q "COMMON_SUBDOMAINS=(" /usr/local/share/sandbox/setup-rules.sh
'

# Verify the script can handle wildcard domains
check "wildcard-handling-code" bash -c '
    grep -qE "if \[\[.*domain.*==.*\*\.\*.*\]\]" /usr/local/share/sandbox/setup-rules.sh
'

# Test the domain extraction logic (without actually running iptables)
check "wildcard-domain-extraction" bash -c '
    # The config should show the wildcard domains were processed
    grep -E "(facebook\.com|twitter\.com|example\.com)" /etc/sandbox/config
'

echo "Wildcard domain blocking test completed"
reportResults