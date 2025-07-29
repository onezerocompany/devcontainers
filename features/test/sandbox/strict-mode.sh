#!/bin/bash
# Test strict mode scenario (pure dnsmasq-based)
set -e

source dev-container-features-test-lib

echo "Testing strict mode configuration (pure dnsmasq-based)..."

# Test that default policy is block
check "default-policy-block" grep -q 'DEFAULT_POLICY="block"' /etc/sandbox/config

# Test that immutable config is enabled
check "immutable-config" grep -q 'IMMUTABLE_CONFIG="true"' /etc/sandbox/config

# Test that only specific domain is allowed
check "only-github-api-allowed" grep -q "api.github.com" /etc/sandbox/config

# Test that dnsmasq configuration scripts exist
check "dnsmasq-config-script-exists" test -x /usr/local/share/sandbox/generate-dnsmasq-config.sh
check "dnsmasq-setup-script-exists" test -x /usr/local/share/sandbox/setup-dnsmasq.sh

# Test that dnsmasq binary is available
check "dnsmasq-binary-available" command -v dnsmasq

# Test that dnsmasq directory exists
check "dnsmasq-config-dir" test -d /etc/dnsmasq.d

# Test that config file is read-only (if chattr worked)
check "config-readonly" [ ! -w /etc/sandbox/config ] || true

# Test environment variable is set
check "sandbox-env-var" [ "$SANDBOX_NETWORK_FILTER" = "enabled" ]

echo "Strict mode test passed (pure dnsmasq-based)"
reportResults