#!/bin/bash
# Test DNS query logging enabled scenario (pure dnsmasq-based)
set -e

source dev-container-features-test-lib

echo "Testing DNS query logging configuration (pure dnsmasq-based)..."

# Test that query logging is enabled in config
check "query-logging-enabled" grep -q 'LOG_QUERIES="true"' /etc/sandbox/config

# Test that dnsmasq configuration generation script exists
check "dnsmasq-config-script-exists" test -x /usr/local/share/sandbox/generate-dnsmasq-config.sh

# Test that dnsmasq setup script exists
check "dnsmasq-setup-script-exists" test -x /usr/local/share/sandbox/setup-dnsmasq.sh

# Test that dnsmasq directory exists
check "dnsmasq-config-dir" test -d /etc/dnsmasq.d

# Test that dnsmasq binary is available
check "dnsmasq-binary-available" command -v dnsmasq

# Test that sandbox initialization script exists
check "sandbox-init-script-exists" test -x /usr/local/share/sandbox/sandbox-init.sh

# Test environment variable is set
check "sandbox-env-var" [ "$SANDBOX_NETWORK_FILTER" = "enabled" ]

echo "DNS query logging test passed (pure dnsmasq-based)"
reportResults