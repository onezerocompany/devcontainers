#!/bin/bash
# Network debugging tools installation
set -e

# Check if this tool should be installed
if [ "${NETWORKDEBUG:-true}" != "true" ]; then
    echo "  ⏭️  Skipping network debugging tools installation (disabled)"
    return 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/utils.sh"

echo "  🔧 Adding network debugging tools to package list..."

# Network debugging and testing tools
debug_packages="netcat-openbsd tcpdump traceroute telnet socat iperf3"

if is_debian_based; then
    add_pkgs "$debug_packages"
fi

echo "  ✓ Network debugging tools added to package list (netcat, tcpdump, traceroute, telnet, socat, iperf3)"