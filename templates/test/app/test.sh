#!/bin/bash

source dev-container-features-test-lib

test() {
  zsh -c "source ~/.zshrc && $1"
}

if [ "$(uname -m)" == "aarch64" ]; then
  echo "Flutter is not supported on arm64 yet."
  exit 0
fi

# Definition specific tests
check "dart" test "dart --version"
check "flutter" test "flutter --version"
check "fvm" test "fvm --version"

# Report result
reportResults