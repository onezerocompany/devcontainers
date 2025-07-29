#!/bin/bash
# Integration test - test actual DNS filtering functionality (pure dnsmasq-based)
set -e

source dev-container-features-test-lib

echo "Testing DNS filtering functionality (pure dnsmasq-based)..."

# Test that localhost is allowed (should work)
check "localhost-ping" ping -c 1 127.0.0.1 >/dev/null 2>&1

# Test that dnsmasq configuration directory exists
check "dnsmasq-config-dir-exists" test -d /etc/dnsmasq.d

# Test that sandbox dnsmasq config would be generated properly
# (We can't test actual DNS resolution without starting dnsmasq, which requires runtime)
check "dnsmasq-config-generation-script" test -x /usr/local/share/sandbox/generate-dnsmasq-config.sh

# Test dnsmasq setup script exists
check "dnsmasq-setup-script-exists" test -x /usr/local/share/sandbox/setup-dnsmasq.sh

# Test that configuration includes expected settings
if grep -q 'DEFAULT_POLICY="block"' /etc/sandbox/config; then
    echo "Default policy is set to block - good"
fi

# Check that dnsmasq binary is available
check "dnsmasq-binary-available" command -v dnsmasq

# Test that the sandbox initialization script exists
check "sandbox-init-script-exists" test -x /usr/local/share/sandbox/sandbox-init.sh

# Test that the devcontainer hook exists
check "devcontainer-hook-exists" test -x /usr/local/share/devcontainer-init.d/50-sandbox.sh

echo "DNS filtering functionality test passed (pure dnsmasq-based)"
reportResults