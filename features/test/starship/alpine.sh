#!/bin/bash

set -e

source dev-container-features-test-lib

echo "Testing starship installation on Alpine..."

# Test 1: Check if starship is installed
check "starship installed" command -v starship

# Test 2: Check if starship is configured in profile
check "starship in profile" grep -q "starship init" /etc/profile

# Test 3: Check if configuration file exists
check "starship config exists" test -f /etc/starship/starship.toml

# Test 4: Check if environment variable is set
check "starship env var" test -f /etc/profile.d/starship.sh

# Test 5: Check if starship can be initialized
check "starship init works" bash -c 'eval "$(starship init bash)"'

# Test 6: Verify default configuration content
check "default config has format" grep -q "^format = " /etc/starship/starship.toml

reportResults