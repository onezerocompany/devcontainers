#!/bin/bash -e

INSTALL_YARN=${YARN:-"false"}
INSTALL_PNPM=${PNPM:-"false"}
NODE_VERSION=${VERSION:-"lts"}
GLOBAL_PACKAGES=${GLOBAL_PACKAGES:-""}

export SHELL="zsh"

# Install NVM
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash

# Load NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

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

# Install Node.js
if [ "$NODE_VERSION" = "lts" ]; then
  nvm install --lts --default
  nvm use --lts
else
  nvm install $NODE_VERSION --default
  nvm use $NODE_VERSION
fi

# Install Yarn
if [ "$INSTALL_YARN" = "true" ]; then
  npm install -g yarn
fi

# Install PNPM
if [ "$INSTALL_PNPM" = "true" ]; then
  curl -fsSL https://get.pnpm.io/install.sh | sh -
fi

# Install global packages
# split by comma and remove leading and trailing whitespaces
GLOBAL_PACKAGES=$(echo $GLOBAL_PACKAGES | tr -d '[:space:]')
if [ -n "$GLOBAL_PACKAGES" ]; then
  OLD_IFS=$IFS
  IFS=','
  for package in $GLOBAL_PACKAGES; do
    npm install -g $package
  done
  IFS=$OLD_IFS
fi
