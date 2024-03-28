#!/bin/bash

# Optional: Import test library
source dev-container-features-test-lib

check "bun" bash --version | grep "1.0.0"

# Report result
reportResults