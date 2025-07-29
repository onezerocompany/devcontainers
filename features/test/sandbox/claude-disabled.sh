#!/bin/bash
# Test Claude integration disabled (pure dnsmasq-based)
set -e

source dev-container-features-test-lib

echo "Testing Claude integration disabled configuration (pure dnsmasq-based)..."

# Test that Claude integration is disabled
check "claude-webfetch-disabled" grep -q 'ALLOW_CLAUDE_WEBFETCH_DOMAINS="false"' /etc/sandbox/config

# Test that default policy is block
check "default-policy-block" grep -q 'DEFAULT_POLICY="block"' /etc/sandbox/config

# Test that dnsmasq configuration generation script exists
check "dnsmasq-config-script-exists" test -x /usr/local/share/sandbox/generate-dnsmasq-config.sh

# Test that dnsmasq setup script exists
check "dnsmasq-setup-script-exists" test -x /usr/local/share/sandbox/setup-dnsmasq.sh

# Test that dnsmasq directory exists
check "dnsmasq-config-dir" test -d /etc/dnsmasq.d

# Test that dnsmasq binary is available
check "dnsmasq-binary-available" command -v dnsmasq

# Test that the dnsmasq config script handles the Claude disable flag
check "claude-disabled-handling" bash -c '
    # Check that the script has the ALLOW_CLAUDE_WEBFETCH_DOMAINS parameter
    grep -q "ALLOW_CLAUDE_WEBFETCH_DOMAINS" /usr/local/share/sandbox/generate-dnsmasq-config.sh
'

# Test environment variable is still set (sandbox is enabled, just Claude integration is off)
check "sandbox-env-var" [ "$SANDBOX_NETWORK_FILTER" = "enabled" ]

# Test that sandbox initialization script exists
check "sandbox-init-script-exists" test -x /usr/local/share/sandbox/sandbox-init.sh

echo "Claude disabled test passed (pure dnsmasq-based)"
reportResults