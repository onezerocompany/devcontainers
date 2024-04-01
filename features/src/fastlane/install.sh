#!/bin/bash -e

USER=${USER:-"zero"}
VERSION=${VERSION:-"latest"}

# install locales
apt-get install -y locales
locale-gen en_US.UTF-8

# set locale to UTF-8 
echo "export LC_ALL=en_US.UTF-8" >> /home/$USER/.zshrc
echo "export LANG=en_US.UTF-8" >> /home/$USER/.zshrc
echo "export LC_ALL=en_US.UTF-8" >> /home/$USER/.bashrc
echo "export LANG=en_US.UTF-8" >> /home/$USER/.bashrc

gem install fastlane
