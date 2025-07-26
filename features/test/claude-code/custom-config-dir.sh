#!/bin/bash

set -e

source dev-container-features-test-lib

# Custom config directory scenario test - verify claude-code works with custom config dir
check "claude-code command exists" command -v claude-code

# Report results
reportResults