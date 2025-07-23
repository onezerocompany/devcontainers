#!/bin/bash
# DNS tools installation
set -e

# Check if this tool should be installed
if [ "${DNSTOOLS:-true}" != "true" ]; then
    echo "  ⏭️  Skipping DNS tools installation (disabled)"
    return 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/utils.sh"

echo "  🔧 Adding DNS tools to package list..."

# DNS tools
dns_packages="dnsutils whois"

if is_debian_based; then
    add_pkgs "$dns_packages"
fi