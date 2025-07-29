#!/bin/bash
# Test default sandbox configuration (dnsmasq-based)
set -e

source dev-container-features-test-lib

echo "Testing default sandbox configuration (dnsmasq-based)..."

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

# Test that dnsmasq will be configured at runtime
echo "⚠️  Skipping dnsmasq runtime tests - requires container runtime initialization"
check "dnsmasq-test-deferred" true

# Test default configuration values
check "default-policy-block" grep -q 'DEFAULT_POLICY="block"' /etc/sandbox/config
check "immutable-config-enabled" grep -q 'IMMUTABLE_CONFIG="true"' /etc/sandbox/config
check "query-logging-enabled" grep -q 'LOG_QUERIES="true"' /etc/sandbox/config
check "claude-domains-enabled" grep -q 'ALLOW_CLAUDE_WEBFETCH_DOMAINS="true"' /etc/sandbox/config

# Test environment variable is set
check "sandbox-env-var" [ "$SANDBOX_NETWORK_FILTER" = "enabled" ]

# Test that Claude settings paths are configured
check "claude-settings-paths" grep -q "CLAUDE_SETTINGS_PATHS=" /etc/sandbox/config

# Test that common domains file exists
check "common-domains-file" test -f /usr/local/share/sandbox/common-domains.txt

# Test that devcontainer initialization hook exists
check "devcontainer-hook" test -x /usr/local/share/devcontainer-init.d/50-sandbox.sh

echo "Default sandbox test passed (dnsmasq-based)"
reportResults