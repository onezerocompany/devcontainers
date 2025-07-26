#!/bin/bash
# Test Claude integration disabled
set -e

source dev-container-features-test-lib

echo "Testing Claude integration disabled configuration..."

# Test that Claude integration is disabled
check "claude-webfetch-disabled" grep -q 'ALLOW_CLAUDE_WEBFETCH_DOMAINS="false"' /etc/sandbox/config

# Test that default policy is block
check "default-policy-block" grep -q 'DEFAULT_POLICY="block"' /etc/sandbox/config

# Create mock Claude settings files
mkdir -p /workspace/.claude
cat > /workspace/.claude/settings.json << 'EOF'
{
  "tools": {
    "WebFetch": {
      "permissions": {
        "allowed_domains": ["should.not.be.allowed.com", "*.test.com"]
      }
    }
  }
}
EOF

# Test that Claude settings are NOT processed when disabled
check "claude-settings-ignored" bash -c '
    # Run the setup rules script
    /usr/local/share/sandbox/setup-rules.sh
    
    # Claude domains should NOT be in allowed list
    ! grep -q "should.not.be.allowed.com" /etc/sandbox/config &&
    ! grep -q "should.not.be.allowed.com" /etc/sandbox/allowed_domains 2>/dev/null
'

# Test that wildcard domains from Claude settings are NOT processed
check "claude-wildcards-ignored" bash -c '
    ! grep -q "test.com" /etc/dnsmasq.d/sandbox.conf 2>/dev/null ||
    ! grep -q "address=/test.com/" /etc/dnsmasq.d/sandbox.conf 2>/dev/null
'

# Test environment variable is still set (sandbox is enabled, just Claude integration is off)
check "sandbox-env-var" [ "$SANDBOX_NETWORK_FILTER" = "enabled" ]

# Test that iptables rules still work with default block policy
check "default-block-active" iptables -t filter -L SANDBOX_OUTPUT | grep -q "REJECT"

echo "Claude disabled test passed"
reportResults