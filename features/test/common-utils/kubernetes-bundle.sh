#!/bin/bash

# Test that Kubernetes bundle tools are installed

set -e

# Source dev-container-features-test-lib
source dev-container-features-test-lib

# Check that Kubernetes tools are installed
check "kubectl" kubectl --version
check "k9s" k9s version
check "helm" helm version
check "flux" flux --version
check "kustomize" kustomize version
check "kind" kind --version

# Check that k9s config exists
check "k9s config exists" test -f /home/zero/.config/k9s/config.yaml

# Check completions are installed
check "kubectl completion" test -f /home/zero/.local/share/bash-completion/completions/kubectl
check "helm completion" test -f /home/zero/.local/share/bash-completion/completions/helm
check "flux completion" test -f /home/zero/.local/share/bash-completion/completions/flux

# Check that Kubernetes aliases are available in shell config
check "kubectl aliases in bashrc" grep -q "alias k='kubectl'" /home/zero/.bashrc || echo "kubectl aliases not found"

# Report results
reportResults