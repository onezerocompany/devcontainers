#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Check if firewall tools are installed
check "iptables installed" bash -c "which iptables"
check "ipset installed" bash -c "which ipset"
check "dig installed" bash -c "which dig"

# Check if firewall script exists
check "firewall script exists" bash -c "test -f /usr/local/share/claude-code/init-firewall.sh"
check "firewall script executable" bash -c "test -x /usr/local/share/claude-code/init-firewall.sh"

# Check if directories exist for volume mounts
check "claude directory exists" bash -c "test -d ~/.claude"
check "anthropic directory exists" bash -c "test -d ~/.anthropic"
check "claude-code config directory exists" bash -c "test -d ~/.config/claude-code"

# Check if claude-code CLI is installed
check "claude-code CLI installed" bash -c "which claude-code || echo 'Note: claude-code CLI requires npm to be installed'"

# Check if sudoers file was created (if not root)
if [ "$(id -u)" != "0" ]; then
    check "sudoers file exists" bash -c "test -f /etc/sudoers.d/claude-code"
fi

# Report result
reportResults