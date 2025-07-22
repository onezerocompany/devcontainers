#\!/bin/bash

# Test that MOTD can be disabled

set -e

# Source dev-container-features-test-lib
source dev-container-features-test-lib

# Check that MOTD script does NOT exist when disabled
check "no motd script" bash -c "\! test -f ~/.config/modern-shell-motd.sh"

# Check that shell config does NOT include MOTD
check "no motd in bashrc" bash -c "\! grep -q 'modern-shell-motd.sh' ~/.bashrc"

# Report results
reportResults
EOF < /dev/null