#!/bin/bash
# Test wildcard domain blocking functionality
set -e

source dev-container-features-test-lib

echo "Testing wildcard domain blocking functionality..."

# DNS filtering is no longer used - this entire test file is obsolete
# The sandbox feature now uses iptables rules only, not DNS filtering

echo "DNS filtering has been removed from the sandbox feature"
echo "Wildcard domain blocking is no longer supported"

# Minimal test to ensure the sandbox feature is still enabled
check "sandbox-env-var" [ "$SANDBOX_NETWORK_FILTER" = "enabled" ]

echo "Wildcard domain blocking test completed (now a no-op)"
reportResults