#!/bin/bash

set -e

echo "Testing sandbox integration in base devcontainer..."

# Test 1: Check if sandbox scripts are installed
echo "Test 1: Checking sandbox installation..."
if [ -f "/usr/local/share/sandbox/init-firewall.sh" ]; then
    echo "✓ Firewall initialization script is present"
else
    echo "✗ Firewall initialization script is missing!"
    exit 1
fi

if [ -f "/usr/local/bin/devcontainer-entrypoint" ]; then
    echo "✓ Entrypoint wrapper is present"
else
    echo "✗ Entrypoint wrapper is missing!"
    exit 1
fi

# Test 2: Check script permissions
echo -e "\nTest 2: Checking script permissions..."
if [ "$(stat -c '%U' /usr/local/bin/devcontainer-entrypoint)" = "root" ]; then
    echo "✓ Entrypoint wrapper is owned by root"
else
    echo "✗ Entrypoint wrapper is not owned by root!"
    exit 1
fi

if [ "$(stat -c '%U' /usr/local/share/sandbox/init-firewall.sh)" = "root" ]; then
    echo "✓ Firewall script is owned by root"
else
    echo "✗ Firewall script is not owned by root!"
    exit 1
fi

# Test 3: Check if required packages are installed
echo -e "\nTest 3: Checking required packages..."
for pkg in iptables ipset dnsutils curl sudo libcap2-bin; do
    if dpkg -s "$pkg" >/dev/null 2>&1; then
        echo "✓ Package $pkg is installed"
    else
        echo "✗ Package $pkg is missing!"
        exit 1
    fi
done

# Test 4: Check sudoers configuration
echo -e "\nTest 4: Checking sudoers configuration..."
if [ -f "/etc/sudoers.d/sandbox" ]; then
    echo "✓ Sudoers file for sandbox is present"
else
    echo "✗ Sudoers file for sandbox is missing!"
    exit 1
fi

# Test 5: Test sandbox immutability
echo -e "\nTest 5: Testing sandbox immutability..."
# First, simulate initial container start with sandbox enabled
export DEVCONTAINER_SANDBOX_ENABLED="true"
export DEVCONTAINER_SANDBOX_FIREWALL="false"
export DEVCONTAINER="true"

# Clean up any existing state
sudo rm -rf /var/lib/devcontainer-sandbox 2>/dev/null || true

# Run entrypoint to initialize state
if bash /usr/local/bin/devcontainer-entrypoint echo "First run" >/dev/null 2>&1; then
    echo "✓ Entrypoint initializes successfully"
else
    echo "✗ Entrypoint initialization failed!"
    exit 1
fi

# Verify state file was created
if [ -f "/var/lib/devcontainer-sandbox/enabled" ]; then
    echo "✓ Sandbox state file created"
else
    echo "✗ Sandbox state file not created!"
    exit 1
fi

# Now try to change the environment variable and run again
export DEVCONTAINER_SANDBOX_ENABLED="false"
OUTPUT=$(bash /usr/local/bin/devcontainer-entrypoint echo "Second run" 2>&1)
if echo "$OUTPUT" | grep -q "Sandbox mode is enabled (immutable)"; then
    echo "✓ Sandbox remains enabled despite env var change"
else
    echo "✗ Sandbox was disabled by env var change!"
    echo "Output: $OUTPUT"
    exit 1
fi

# Clean up
sudo rm -rf /var/lib/devcontainer-sandbox 2>/dev/null || true

# Test 6: Verify user cannot modify protected files
echo -e "\nTest 6: Testing file protection..."
if ! touch /usr/local/bin/devcontainer-entrypoint 2>/dev/null; then
    echo "✓ User cannot modify entrypoint wrapper"
else
    echo "✗ User can modify entrypoint wrapper!"
    exit 1
fi

if ! touch /usr/local/share/sandbox/init-firewall.sh 2>/dev/null; then
    echo "✓ User cannot modify firewall script"
else
    echo "✗ User can modify firewall script!"
    exit 1
fi

echo -e "\nAll sandbox integration tests passed!"