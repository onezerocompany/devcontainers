#!/usr/bin/env bash -e

INSTALL_YARN=${YARN:-"false"}
INSTALL_PNPM=${PNPM:-"false"}
NODE_VERSION=${VERSION:-"lts"}
GLOBAL_PACKAGES=${GLOBAL_PACKAGES:-""}

# Install NVM
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash

# Load NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Install NVM into bash
echo "export NVM_DIR=\"$NVM_DIR\"" >> $HOME/.bashrc
echo "[ -s \"\$NVM_DIR/nvm.sh\" ] && \\. \"\$NVM_DIR/nvm.sh\"" >> $HOME/.bashrc
echo "[ -s \"\$NVM_DIR/bash_completion\" ] && \\. \"\$NVM_DIR/bash_completion\"" >> $HOME/.bashrc

# Install NVM into zsh (if it exists)
if [ -f "$HOME/.zshrc" ]; then
  echo "export NVM_DIR=\"$NVM_DIR\"" >> $HOME/.zshrc
  echo "[ -s \"\$NVM_DIR/nvm.sh\" ] && \\. \"\$NVM_DIR/nvm.sh\"" >> $HOME/.zshrc
  echo "[ -s \"\$NVM_DIR/bash_completion\" ] && \\. \"\$NVM_DIR/bash_completion\"" >> $HOME/.zshrc
fi

# Install NVM into fish (if it exists)
if [ -f "$HOME/.config/fish/config.fish" ]; then
  echo "set -x NVM_DIR \"$NVM_DIR\"" >> $HOME/.config/fish/config.fish
  echo "[ -s \"\$NVM_DIR/nvm.sh\" ]; and source \"\$NVM_DIR/nvm.sh\"" >> $HOME/.config/fish/config.fish
  echo "[ -s \"\$NVM_DIR/bash_completion\" ]; and source \"\$NVM_DIR/bash_completion\"" >> $HOME/.config/fish/config.fish
fi

# Install Node.js
nvm install $NODE_VERSION
nvm alias default $NODE_VERSION

# Install Yarn
if [ "$INSTALL_YARN" = "true" ]; then
  npm install -g yarn
fi

# Install PNPM
if [ "$INSTALL_PNPM" = "true" ]; then
  npm install -g pnpm
fi

# Install global packages
# split by comma and remove leading and trailing whitespaces
IFS=',' read -ra packages <<< "$GLOBAL_PACKAGES"
for package in "${packages[@]}"; do
  npm install -g $package
done