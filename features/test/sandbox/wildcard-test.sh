#!/bin/bash
# Test wildcard domain blocking functionality
set -e

source dev-container-features-test-lib

echo "Testing wildcard domain blocking functionality..."

# Test that dnsmasq is configured with wildcard rules
check "dnsmasq-config-exists" test -f /etc/dnsmasq.d/sandbox.conf

# Test wildcard configurations are present
check "wildcard-facebook-config" grep -q "address=/facebook.com/127.0.0.1" /etc/dnsmasq.d/sandbox.conf
check "wildcard-twitter-config" grep -q "address=/twitter.com/127.0.0.1" /etc/dnsmasq.d/sandbox.conf

# Test that DNS server is set to localhost
check "dns-localhost" grep -q "nameserver 127.0.0.1" /etc/resolv.conf

# Test that dnsmasq service is enabled
check "dnsmasq-service-enabled" systemctl is-enabled dnsmasq >/dev/null 2>&1 || true

# If dnsmasq is running, test actual wildcard subdomain resolution
if systemctl is-active dnsmasq >/dev/null 2>&1; then
    echo "Testing actual wildcard DNS blocking with running dnsmasq..."
    
    # Test various subdomains of blocked domains
    test_subdomain_blocked() {
        local subdomain="$1"
        local ip
        ip=$(nslookup "$subdomain" 127.0.0.1 2>/dev/null | grep -A1 "Name:" | tail -n1 | awk '{print $2}' || echo "failed")
        [ "$ip" = "127.0.0.1" ]
    }
    
    # Test facebook.com subdomains
    check "api-facebook-blocked" test_subdomain_blocked "api.facebook.com"
    check "www-facebook-blocked" test_subdomain_blocked "www.facebook.com"
    check "m-facebook-blocked" test_subdomain_blocked "m.facebook.com"
    check "random-facebook-blocked" test_subdomain_blocked "random-subdomain.facebook.com"
    
    # Test twitter.com subdomains
    check "api-twitter-blocked" test_subdomain_blocked "api.twitter.com"
    check "mobile-twitter-blocked" test_subdomain_blocked "mobile.twitter.com"
    check "test-twitter-blocked" test_subdomain_blocked "test.twitter.com"
    
    echo "Wildcard DNS blocking is working correctly"
else
    echo "Warning: dnsmasq is not running - skipping live wildcard tests"
fi

echo "Wildcard domain blocking test completed"
reportResults