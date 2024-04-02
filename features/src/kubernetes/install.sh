#!/bin/bash -e

USER=${USER:-"zero"}
INSTALL_KUBECTL=${KUBECTL:-"true"}
INSTALL_HELM=${HELM:-"true"}
INSTALL=${INSTALL:-"true"}

if [ "$INSTALL" != "true" ]; then
  echo "Skipping Kubernetes tools installation"
  exit 0
fi

determine_arch() {
  case $(uname -m) in
    x86_64) echo "amd64";;
    aarch64) echo "arm64";;
    *) echo "unknown";;
  esac
}

arch=$(determine_arch)

# Install kubectl
if [[ "$INSTALL_KUBECTL" == "true" ]]; then
  curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/$arch/kubectl"
  chmod +x ./kubectl
  mv ./kubectl /usr/local/bin/kubectl

  # Add kubectl to PATH
  echo "export PATH=\$PATH:/usr/local/bin/kubectl" >> /home/$USER/.zshrc
  echo "export PATH=\$PATH:/usr/local/bin/kubectl" >> /home/$USER/.bashrc

  # Install kubectl autocompletion
  kubectl completion bash > /etc/bash_completion.d/kubectl
  kubectl completion zsh > /usr/share/zsh/vendor-completions/_kubectl

  # Install kubectl shell autocompletion
  echo "source <(kubectl completion bash)" >> /home/$USER/.bashrc
  echo "source <(kubectl completion zsh)" >> /home/$USER/.zshrc

  # Install kubectl aliases
  echo "alias k=kubectl" >> /home/$USER/.bashrc
  echo "alias k=kubectl" >> /home/$USER/.zshrc
fi

# Install helm
if [[ "$INSTALL_HELM" == "true" ]]; then
  curl -s https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

  # Add helm to PATH
  echo "export PATH=\$PATH:/usr/local/bin/helm" >> /home/$USER/.zshrc
  echo "export PATH=\$PATH:/usr/local/bin/helm" >> /home/$USER/.bashrc

  # Install helm autocompletion
  helm completion bash > /etc/bash_completion.d/helm
  helm completion zsh > /usr/share/zsh/vendor-completions/_helm

  # Install helm shell autocompletion
  echo "source <(helm completion bash)" >> /home/$USER/.bashrc
  echo "source <(helm completion zsh)" >> /home/$USER/.zshrc

  # Install helm aliases
  echo "alias h=helm" >> /home/$USER/.bashrc
  echo "alias h=helm" >> /home/$USER/.zshrc

fi