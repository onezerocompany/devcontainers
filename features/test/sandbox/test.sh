#!/bin/bash
# Sandbox Network Filter Feature Test Script (dnsmasq-based)
set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

echo "Testing Sandbox Network Filter feature (dnsmasq-based)..."

# Test that required scripts are installed
check "sandbox-init-script" test -x /usr/local/share/sandbox/sandbox-init.sh
check "setup-dnsmasq-script" test -x /usr/local/share/sandbox/setup-dnsmasq.sh
check "generate-dnsmasq-config-script" test -x /usr/local/share/sandbox/generate-dnsmasq-config.sh

# Test that configuration directory exists
check "config-directory" test -d /etc/sandbox
check "config-file" test -f /etc/sandbox/config

# Test that required packages are installed
check "dnsmasq" which dnsmasq

# Test that dnsmasq directories exist
check "dnsmasq-config-dir" test -d /etc/dnsmasq.d

# Note: dnsmasq is only started at runtime, not during build
echo "⚠️  Skipping dnsmasq runtime tests - requires container runtime initialization"

# Test configuration file content
check "config-contains-domains" grep -q "BLOCKED_DOMAINS=" /etc/sandbox/config
check "config-contains-policy" grep -q "DEFAULT_POLICY=" /etc/sandbox/config

# Test environment variable is set
check "sandbox-env-var" [ "$SANDBOX_NETWORK_FILTER" = "enabled" ]

# Test that script directories have correct permissions
check "scripts-executable" [ -x /usr/local/share/sandbox/sandbox-init.sh ]

# Test that devcontainer hook exists
check "devcontainer-hook" test -x /usr/local/share/devcontainer-init.d/50-sandbox.sh

# Test that common domains file exists
check "common-domains-file" test -f /usr/local/share/sandbox/common-domains.txt

echo "All basic sandbox tests passed (dnsmasq-based)"

# Report results
reportResults