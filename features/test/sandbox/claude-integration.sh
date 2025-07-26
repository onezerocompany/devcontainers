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

# Test that setup script creates necessary directories
check "claude-settings-processed" bash -c '
    # Run the setup rules script to process Claude settings
    /usr/local/share/sandbox/setup-rules.sh
    
    # Check if domains from Claude settings are added to allowed list
    grep -q "api.example.com" /etc/sandbox/config || 
    grep -q "api.example.com" /etc/sandbox/allowed_domains 2>/dev/null
'

# DNS filtering is no longer used - only check config file
check "claude-wildcard-domains" bash -c '
    grep -q "allowed.com" /etc/sandbox/config
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
    # Re-run setup to pick up new settings
    /usr/local/share/sandbox/setup-rules.sh
    
    # Both domains should be processed
    (grep -q "api.example.com" /etc/sandbox/config || grep -q "api.example.com" /etc/sandbox/allowed_domains 2>/dev/null) &&
    (grep -q "home.example.com" /etc/sandbox/config || grep -q "home.example.com" /etc/sandbox/allowed_domains 2>/dev/null)
'

echo "Claude integration test passed"
reportResults