#!/bin/bash

set -e

source dev-container-features-test-lib

# Test that containers bundle tools are installed
check "docker-compose" which docker-compose
check "podman" which podman
check "buildah" which buildah
check "skopeo" which skopeo
check "k9s" which k9s
check "kubectl" which kubectl
check "helm" which helm
check "dive" which dive

# Test k9s config exists
check "k9s-config" test -f ~/.config/k9s/config.yaml

# Test completion files exist for container tools
check "kubectl-completion-bash" test -f ~/.local/share/bash-completion/completions/kubectl
check "kubectl-completion-zsh" test -f ~/.local/share/zsh/site-functions/_kubectl
check "helm-completion-bash" test -f ~/.local/share/bash-completion/completions/helm
check "helm-completion-zsh" test -f ~/.local/share/zsh/site-functions/_helm

# Report results
reportResults