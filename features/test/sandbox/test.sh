#!/bin/bash
# Sandbox Network Filter Feature Test Script
set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

echo "Testing Sandbox Network Filter feature..."

# Test that required scripts are installed
check "sandbox-init-script" test -x /usr/local/share/sandbox/sandbox-init.sh
check "dns-filter-script" test -x /usr/local/share/sandbox/setup-dns-filter.sh
check "setup-rules-script" test -x /usr/local/share/sandbox/setup-rules.sh

# Test that configuration directory exists
check "config-directory" test -d /etc/sandbox
check "config-file" test -f /etc/sandbox/config

# Test that required packages are installed
check "iptables" which iptables
check "dnsmasq" dpkg -l dnsmasq >/dev/null 2>&1

# Test that iptables rules are set up
check "sandbox-chain-exists" iptables -t filter -L SANDBOX_OUTPUT >/dev/null 2>&1

# Test configuration file content
check "config-contains-domains" grep -q "BLOCKED_DOMAINS=" /etc/sandbox/config
check "config-contains-policy" grep -q "DEFAULT_POLICY=" /etc/sandbox/config

# Test that sandbox chain is attached to OUTPUT
check "sandbox-chain-attached" iptables -t filter -L OUTPUT | grep -q "SANDBOX_OUTPUT"

# Test environment variable is set
check "sandbox-env-var" [ "$SANDBOX_NETWORK_FILTER" = "enabled" ]

# Test systemd service is enabled (if systemd is available)
if command -v systemctl >/dev/null 2>&1; then
    check "service-enabled" systemctl is-enabled sandbox-network-filter.service >/dev/null 2>&1 || true
fi

# Test that script directories have correct permissions
check "scripts-executable" [ -x /usr/local/share/sandbox/sandbox-init.sh ]

# Test DNS filtering - check if blocked domains are in hosts file
check "dns-filter-active" grep -q "facebook.com" /etc/hosts || true

echo "All basic sandbox tests passed"

# Report results
reportResults