#!/bin/bash

# This test file will be executed against a running container built from the Dockerfile

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
# The 'check' command comes from the dev-container-features-test-lib
# Syntax: check <LABEL> <cmd> [args...]

echo "Testing starship installation..."

# Test 1: Check if starship is installed
check "starship installed" command -v starship

# Test 2: Check starship version (if not latest)
if [ "${VERSION}" != "latest" ] && [ -n "${VERSION}" ]; then
    check "starship version" starship --version | grep "${VERSION}"
fi

# Test 3: Check if starship is configured in bash
check "starship in bashrc" grep -q "starship init bash" /etc/bash.bashrc

# Test 4: Check if starship is configured in zsh (if zsh is installed)
if [ -f /etc/zsh/zshrc ]; then
    check "starship in zshrc" grep -q "starship init zsh" /etc/zsh/zshrc
fi

# Test 5: Check if configuration file exists
check "starship config exists" test -f /etc/starship/starship.toml

# Test 6: Check if environment variable is set
check "starship env var" test -f /etc/profile.d/starship.sh

# Test 7: Check if starship can be initialized
check "starship init works" bash -c 'eval "$(starship init bash)"'

# Test 8: Verify default configuration content
check "default config has format" grep -q "^format = " /etc/starship/starship.toml
check "default config has username" grep -q "^\[username\]" /etc/starship/starship.toml
check "default config has directory" grep -q "^\[directory\]" /etc/starship/starship.toml

# Report results
# The reportResults command comes from the test library
reportResults