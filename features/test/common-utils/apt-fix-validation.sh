#!/bin/bash

# Test to specifically validate that the apt installation fix works
# This test checks that the policy-rc.d workaround prevents dbus/systemd errors
set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Test that basic packages are installed (validates apt operations succeeded)
check "curl-installed" which curl
check "wget-installed" which wget  
check "git-installed" which git
check "bash-installed" which bash

# Test that policy-rc.d was properly cleaned up (should not exist after installation)
check "policy-rc-d-cleaned-up" test ! -f /usr/sbin/policy-rc.d

# Test that apt operations work without errors
check "apt-works" bash -c "apt list --installed | grep -q curl"

# Test that services can be queried without dbus errors (basic validation)
check "no-dbus-socket-error" bash -c "! systemctl --version 2>&1 | grep -q 'Failed to open connection to system message bus'"

# Report results
reportResults