#!/bin/bash -e

INSTALL=${INSTALL:-"true"}
USER=${USER:-"zero"}
VERSION=${VERSION:-"latest"}

if [ "$VERSION" = "none" || "$INSTALL" != "true" ]; then
  echo "Skipping Fastlane installation"
  exit 0
fi

# install locales
apt-get install -y locales
locale-gen en_US.UTF-8

# set locale to UTF-8 
echo "export LC_ALL=en_US.UTF-8" >> /home/$USER/.zshrc
echo "export LANG=en_US.UTF-8" >> /home/$USER/.zshrc
echo "export LC_ALL=en_US.UTF-8" >> /home/$USER/.bashrc
echo "export LANG=en_US.UTF-8" >> /home/$USER/.bashrc

if [ "$VERSION" = "latest" ]; then
  gem install fastlane
else 
  gem install fastlane -v $VERSION
fi
