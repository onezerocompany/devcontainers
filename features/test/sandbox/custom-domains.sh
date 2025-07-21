#!/bin/bash
# Test custom domains scenario
set -e

source dev-container-features-test-lib

echo "Testing custom domains configuration..."

# Test that custom allowed domains are configured
check "github-allowed" grep -q "github.com" /etc/sandbox/config
check "openai-allowed" grep -q "api.openai.com" /etc/sandbox/config

# Test that blocked domains are configured
check "facebook-blocked" grep -q "facebook.com" /etc/sandbox/config
check "twitter-blocked" grep -q "twitter.com" /etc/sandbox/config

# Test default policy is block
check "default-policy-block" grep -q 'DEFAULT_POLICY="block"' /etc/sandbox/config

echo "Custom domains test passed"
reportResults