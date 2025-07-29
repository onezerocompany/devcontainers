#!/bin/bash
# Test custom domains scenario (dnsmasq-based)
set -e

source dev-container-features-test-lib

echo "Testing custom domains configuration (dnsmasq-based)..."

# Test that custom allowed domains are configured
check "github-wildcard-allowed" grep -q "*.github.com" /etc/sandbox/config
check "openai-allowed" grep -q "api.openai.com" /etc/sandbox/config
check "googleapis-wildcard-allowed" grep -q "*.googleapis.com" /etc/sandbox/config

# Test that blocked domains are configured
check "facebook-wildcard-blocked" grep -q "*.facebook.com" /etc/sandbox/config
check "twitter-wildcard-blocked" grep -q "*.twitter.com" /etc/sandbox/config

# Verify wildcard handling is present in dnsmasq config generation script
check "wildcard-support" bash -c '
    grep -qE "if \[\[.*domain.*==.*\*\.\*.*\]\]" /usr/local/share/sandbox/generate-dnsmasq-config.sh
'

# Test that dnsmasq blocking function exists
check "dnsmasq-blocking-function" grep -q "add_blocked_domain()" /usr/local/share/sandbox/generate-dnsmasq-config.sh

# Test that dnsmasq address directive is used for blocking
check "dnsmasq-address-directive" grep -q "address=/" /usr/local/share/sandbox/generate-dnsmasq-config.sh

# Test default policy is block
check "default-policy-block" grep -q 'DEFAULT_POLICY="block"' /etc/sandbox/config

echo "Custom domains test passed (dnsmasq-based)"
reportResults