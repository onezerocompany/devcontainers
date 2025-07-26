#!/bin/bash

set -e

source dev-container-features-test-lib

# Basic scenario test with modern-shell feature - just verify claude-code works
check "claude-code command exists" command -v claude-code

# Report results
reportResults