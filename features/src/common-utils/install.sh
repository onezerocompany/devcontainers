#!/bin/sh -e

# Setup user 'zero'
USER=${USER:-"zero"}
if [ ! -d "/home/$USER_NAME" ]; then
  useradd -m -s /bin/bash $USER_NAME
  echo "$USER_NAME:$USER_NAME" | chpasswd
  usermod -aG sudo $USER_NAME
fi

# Install ZSH
INSTALL_ZSH=${ZSH:-"true"}
if [ "$INSTALL_ZSH" = "true" ]; then
  apt-get update
  apt-get install -y zsh
  # Set ZSH as default shell
  ZSH_DEFAULT=${ZSH_DEFAULT:-"true"}
  if [ "$ZSH_DEFAULT" = "true" ]; then
    chsh -s $(which zsh)
  fi

  # Set prompt in zshrc for 'zero' user
  echo 'PROMPT="%F{green}%n@%m%f %F{blue}%~%f %# "' >> ~/.zshrc
fi

# Install MOTD
# INSTALL_MOTD=${MOTD:-"true"}
# if [ "$INSTALL_MOTD" = "true" ]; then

# fi