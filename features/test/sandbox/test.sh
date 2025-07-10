#!/bin/bash

source dev-container-features-test-lib

test() {
  zsh -c "source ~/.zshrc && $1"
}

# Check if firewall script was installed
check "firewall-script-exists" test "test -f /usr/local/share/sandbox/init-firewall.sh"
check "firewall-script-executable" test "test -x /usr/local/share/sandbox/init-firewall.sh"

# Check if required packages were installed
check "iptables" test "command -v iptables"
check "ipset" test "command -v ipset"
check "dig" test "command -v dig"

# Check sudoers configuration for non-root user
check "sudoers-file" test "test -f /etc/sudoers.d/sandbox"

# Report result
reportResults