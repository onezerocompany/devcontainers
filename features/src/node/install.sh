#!/bin/bash -e

INSTALL=${INSTALL:-"true"}
INSTALL_YARN=${YARN:-"false"}
INSTALL_PNPM=${PNPM:-"false"}
NODE_VERSION=${VERSION:-"lts"}
GLOBAL_PACKAGES=${GLOBAL_PACKAGES:-""}
USER=${USER:-"zero"}

if [ "$INSTALL" != "true" ]; then
  echo "Skipping Node.js installation"
  exit 0
fi

# Install NVM
export SHELL="zsh"
su $USER -c "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash"

# Load NVM
USER_HOME=$(su $USER -c "echo \$HOME")
export NVM_DIR="$USER_HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Install NVM into bash
BASHRC_PATH="$USER_HOME/.bashrc"
echo "export NVM_DIR=\"$NVM_DIR\"" >> $BASHRC_PATH
echo "[ -s \"\$NVM_DIR/nvm.sh\" ] && \\. \"\$NVM_DIR/nvm.sh\"" >> $BASHRC_PATH
echo "[ -s \"\$NVM_DIR/bash_completion\" ] && \\. \"\$NVM_DIR/bash_completion\"" >> $BASHRC_PATH

# Install Node.js
if [ "$NODE_VERSION" != "none" ]; then
  if [ "$NODE_VERSION" = "lts" ]; then
    nvm install --lts --default
    nvm use --lts
  else
    nvm install $NODE_VERSION --default
    nvm use $NODE_VERSION
  fi
fi

# Install Yarn
if [ "$INSTALL_YARN" = "true" ]; then
  npm install -g yarn
fi

# Install PNPM
if [ "$INSTALL_PNPM" = "true" ]; then
  su $USER -c "curl -fsSL https://get.pnpm.io/install.sh | sh -"
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
