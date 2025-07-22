#\!/bin/bash

# Test that custom MOTD functionality works correctly

set -e

# Source dev-container-features-test-lib
source dev-container-features-test-lib

# Check that MOTD script exists
check "motd script exists" test -f /home/zero/.config/modern-shell-motd.sh

# Check that MOTD script is executable
check "motd script executable" test -x /home/zero/.config/modern-shell-motd.sh

# Test MOTD script runs without errors
check "motd script runs" /home/zero/.config/modern-shell-motd.sh

# Check that shell config includes MOTD
check "motd in bashrc" grep -q "modern-shell-motd.sh" /home/zero/.bashrc

# Verify custom content is in the MOTD script
check "custom dev logo" grep -q "DEV CONTAINER" /home/zero/.config/modern-shell-motd.sh
check "custom instructions" grep -q "npm start" /home/zero/.config/modern-shell-motd.sh
check "custom notice" grep -q "Development environment" /home/zero/.config/modern-shell-motd.sh

# Report results
reportResults
EOF < /dev/null