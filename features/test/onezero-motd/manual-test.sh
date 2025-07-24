#!/bin/bash

set -e

echo "Testing OneZero MOTD feature..."

# Simulate the environment variables that would be passed by devcontainer
export ASCII_LOGO="   ____              _____              
  / __ \\            |__  /              
 | |  | |_ __   ___   / / ___ _ __ ___  
 | |  | | '_ \\ / _ \\ / / / _ \\ '__/ _ \\ 
 | |__| | | | |  __// /_|  __/ | | (_) |
  \\____/|_| |_|\\___/____|\\___|_|  \\___/ "
export INFO="Welcome to OneZero Development Container"
export MESSAGE="Happy coding!"
export ENABLE="true"

# Create a temporary directory for testing
TEST_DIR=$(mktemp -d)
echo "Using test directory: $TEST_DIR"

# Copy the install script
cp ../../src/onezero-motd/install.sh "$TEST_DIR/"

# Run the install script in a simulated environment
cd "$TEST_DIR"

# Create mock directories
mkdir -p etc/update-motd.d
mkdir -p etc/ssh

# Override paths in the script for testing - use awk instead of sed for portability
awk '{gsub(/\/etc\/update-motd\.d/, "./etc/update-motd.d"); gsub(/\/etc\/ssh/, "./etc/ssh"); gsub(/\/etc\/motd/, "./etc/motd"); gsub(/\/etc\/onezero/, "./etc/onezero"); print}' install.sh > install_test.sh
chmod +x install_test.sh

# Run the install script
echo "Running install script..."
bash ./install_test.sh

echo ""
echo "Testing the generated MOTD..."
echo "=============================="
if [ -f ./etc/update-motd.d/50-onezero ]; then
    bash ./etc/update-motd.d/50-onezero
else
    echo "ERROR: MOTD script not found!"
    exit 1
fi

# Cleanup
cd -
rm -rf "$TEST_DIR"

echo ""
echo "Test completed successfully!"