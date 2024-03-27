#!/bin/bash -e

# Setup user 'zero'
USER=${USER:-"zero"}
if [ ! -d "/home/$USER" ]; then
  useradd -m -s /bin/bash $USER
  echo "$USER:$USER" | chpasswd
  usermod -aG sudo $USER
fi

# Install ZSH
INSTALL_ZSH=${ZSH:-"true"}
if [ "$INSTALL_ZSH" = "true" ]; then
  apt-get update
  apt-get install -y zsh
  # Set ZSH as default shell permanently
  ZSH_DEFAULT=${ZSH_DEFAULT:-"true"}
  if [ "$ZSH_DEFAULT" = "true" ]; then
    chsh -s $(which zsh)
    chsh -s $(which zsh) $USER
  fi

  # Set prompt in zshrc for 'zero' user
  echo 'PROMPT="%F{green}%n@%m%f %F{blue}%~%f %# "' >> ~/.zshrc
fi