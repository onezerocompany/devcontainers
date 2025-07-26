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

# Test that Claude settings can be extracted correctly
check "claude-settings-processed" bash -c '
    # Test the domain extraction script directly (without iptables)
    # Set workspace folder for the extraction script
    export WORKSPACE_FOLDER=/workspaces/$(ls /workspaces/ | head -n1)
    
    # Extract domains from Claude settings
    extracted_domains=$(/usr/local/share/sandbox/extract-claude-domains.sh ".claude/settings.json,~/.claude/settings.json,/workspace/.claude/settings.local.json" 2>/dev/null | tail -n +2)
    
    # Check if expected domains were extracted
    echo "$extracted_domains" | grep -E "(api\.example\.com|docs\.test\.com)" >/dev/null
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
    # Test that the extraction script can read from multiple paths
    export WORKSPACE_FOLDER=/workspaces/$(ls /workspaces/ | head -n1)
    
    # Extract domains from all Claude settings files
    extracted_domains=$(/usr/local/share/sandbox/extract-claude-domains.sh ".claude/settings.json,~/.claude/settings.json,/workspace/.claude/settings.local.json" 2>/dev/null | tail -n +2)
    
    # Check if domains from both files were extracted
    echo "$extracted_domains" | grep -q "api.example.com" &&
    echo "$extracted_domains" | grep -q "home.example.com"
'

echo "Claude integration test passed"
reportResults