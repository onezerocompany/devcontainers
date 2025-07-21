#!/bin/bash
# Integration test - test actual network blocking functionality
set -e

source dev-container-features-test-lib

echo "Testing network blocking functionality..."

# Test that localhost is allowed (should work)
check "localhost-ping" ping -c 1 127.0.0.1 >/dev/null 2>&1

# Test that blocked domains are redirected in hosts file 
check "blocked-domain-in-hosts" grep -q "127.0.0.1.*facebook.com" /etc/hosts
check "blocked-domain-in-hosts-twitter" grep -q "127.0.0.1.*twitter.com" /etc/hosts

# Test that DNS resolution is redirected for blocked domains
blocked_ip=$(getent hosts facebook.com | awk '{print $1}' || true)
check "facebook-redirected-to-localhost" [ "$blocked_ip" = "127.0.0.1" ]

# Test iptables rules are working for Docker networks
check "docker-network-allowed" iptables -t filter -L SANDBOX_OUTPUT | grep -q "172.16.0.0/12"
check "local-network-allowed" iptables -t filter -L SANDBOX_OUTPUT | grep -q "10.0.0.0/8"

# Test that external traffic is blocked by default (when default policy is block)
if grep -q 'DEFAULT_POLICY="block"' /etc/sandbox/config; then
    check "external-traffic-blocked" iptables -t filter -L SANDBOX_OUTPUT | grep -q "REJECT"
fi

echo "Network blocking functionality test passed"
reportResults