#!/bin/bash
# Test DNS query logging disabled scenario (pure dnsmasq-based)
set -e

source dev-container-features-test-lib

echo "Testing DNS query logging disabled configuration (pure dnsmasq-based)..."

# Test that query logging is disabled in config
check "query-logging-disabled" grep -q 'LOG_QUERIES="false"' /etc/sandbox/config

# Test that dnsmasq configuration generation script exists
check "dnsmasq-config-script-exists" test -x /usr/local/share/sandbox/generate-dnsmasq-config.sh

# Test that dnsmasq setup script exists
check "dnsmasq-setup-script-exists" test -x /usr/local/share/sandbox/setup-dnsmasq.sh

# Test that dnsmasq directory exists
check "dnsmasq-config-dir" test -d /etc/dnsmasq.d

# Test that dnsmasq binary is available
check "dnsmasq-binary-available" command -v dnsmasq

# Test that configuration is otherwise normal
check "default-policy" grep -q 'DEFAULT_POLICY=' /etc/sandbox/config
check "immutable-config" grep -q 'IMMUTABLE_CONFIG=' /etc/sandbox/config
check "claude-domains" grep -q 'ALLOW_CLAUDE_WEBFETCH_DOMAINS=' /etc/sandbox/config

# Test environment variable is set
check "sandbox-env-var" [ "$SANDBOX_NETWORK_FILTER" = "enabled" ]

# Test that sandbox initialization script exists
check "sandbox-init-script-exists" test -x /usr/local/share/sandbox/sandbox-init.sh

echo "DNS query logging disabled test passed (pure dnsmasq-based)"
reportResults