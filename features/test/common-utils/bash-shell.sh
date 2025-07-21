#!/bin/bash

set -e

source dev-container-features-test-lib

# Test that default shell is bash
check "default-shell-bash" bash -c "getent passwd $(whoami) | cut -d: -f7 | grep -q '/bin/bash'"

# Report results
reportResults