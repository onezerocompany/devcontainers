#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "terraform" terraform -version
check "tfsec" tfsec --version
check "tflint" tflint --version
check "terraform-docs" terraform-docs --version
check "tf-summarize" tf-summarize -v

# Report result
reportResults