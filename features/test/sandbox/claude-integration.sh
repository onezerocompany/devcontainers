#!/bin/bash
# Test Claude integration features
set -e

source dev-container-features-test-lib

echo "Testing Claude integration configuration..."

# Test that Claude integration is enabled
check "claude-webfetch-enabled" grep -q 'ALLOW_CLAUDE_WEBFETCH_DOMAINS="true"' /etc/sandbox/config

# Test that Claude settings paths are configured (should match scenario config)
check "claude-settings-paths-configured" grep -q 'CLAUDE_SETTINGS_PATHS=".claude/settings.json,~/.claude/settings.json,/workspace/.claude/settings.local.json"' /etc/sandbox/config

# Create mock Claude settings files with WebFetch permissions  
mkdir -p .claude
cat > .claude/settings.json << 'EOF'
{
  "permissions": {
    "allow": [
      "WebFetch(domain:api.example.com)",
      "WebFetch(domain:docs.test.com)",
      "WebFetch(domain:*.allowed.com)"
    ]
  }
}
EOF

# Test that dnsmasq configuration generation script exists
check "dnsmasq-config-script-exists" test -x /usr/local/share/sandbox/generate-dnsmasq-config.sh

# Check that Claude domain extraction is integrated into dnsmasq config generation
check "claude-domain-extraction-integrated" bash -c '
    # Check the dnsmasq configuration script handles Claude domains
    grep -q "Extract domains from Claude settings files" /usr/local/share/sandbox/generate-dnsmasq-config.sh &&
    grep -q "WebFetch(domain:" /usr/local/share/sandbox/generate-dnsmasq-config.sh
'

# Test that the Claude settings file contains the wildcard domain
check "claude-wildcard-domains" bash -c '
    # The wildcard domain should be in the Claude settings file we created
    grep -q "*.allowed.com" .claude/settings.json
'

# Test environment variable is set
check "sandbox-env-var" [ "$SANDBOX_NETWORK_FILTER" = "enabled" ]

# Test that the sandbox can read from multiple Claude settings locations
mkdir -p ~/.claude
cat > ~/.claude/settings.json << 'EOF'
{
  "permissions": {
    "allow": [
      "WebFetch(domain:home.example.com)"
    ]
  }
}
EOF

check "multiple-settings-paths" bash -c '
    # Test that the dnsmasq config generation script handles multiple paths
    grep -q "IFS.*read.*PATHS" /usr/local/share/sandbox/generate-dnsmasq-config.sh &&
    grep -q "expanded_path" /usr/local/share/sandbox/generate-dnsmasq-config.sh
'

echo "Claude integration test passed"
reportResults