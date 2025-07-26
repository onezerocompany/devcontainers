#!/bin/bash
# Test custom domains scenario
set -e

source dev-container-features-test-lib

echo "Testing custom domains configuration..."

# Test that custom allowed domains are configured
check "github-wildcard-allowed" grep -q "*.github.com" /etc/sandbox/config
check "openai-allowed" grep -q "api.openai.com" /etc/sandbox/config
check "googleapis-wildcard-allowed" grep -q "*.googleapis.com" /etc/sandbox/config

# Test that blocked domains are configured
check "facebook-wildcard-blocked" grep -q "*.facebook.com" /etc/sandbox/config
check "twitter-wildcard-blocked" grep -q "*.twitter.com" /etc/sandbox/config

# Verify wildcard handling is present in setup script
check "wildcard-support" bash -c '
    grep -q "COMMON_SUBDOMAINS=(" /usr/local/share/sandbox/setup-rules.sh &&
    grep -q "Scanning common subdomains for wildcard domain" /usr/local/share/sandbox/setup-rules.sh
'

# Test default policy is block
check "default-policy-block" grep -q 'DEFAULT_POLICY="block"' /etc/sandbox/config

echo "Custom domains test passed"
reportResults