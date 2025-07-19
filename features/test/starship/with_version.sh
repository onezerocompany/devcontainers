#!/bin/bash

set -e

source dev-container-features-test-lib

# Test specific version installation
check "starship version 1.17.1" starship --version | grep "1.17.1"

reportResults