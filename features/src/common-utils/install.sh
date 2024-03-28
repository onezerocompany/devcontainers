#!/bin/bash -e

# auto-cd
AUTO_CD=${AUTO_CD:-"false"}
if [ "$AUTO_CD" = "true" ]; then
  # add auto-cd to zshrc if available
  if [ -f ~/.zshrc ]; then
    echo "Adding auto-cd to zshrc"
    echo "setopt auto_cd" >> ~/.zshrc
  fi
fi

# zoxide
ZOXIDE=${ZOXIDE:-"false"}
if [ "$ZOXIDE" = "true" ]; then
  # Install zoxide
  curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
  # add zoxide to zshrc if available
  if [ -f ~/.zshrc ]; then
    echo "Adding zoxide to zshrc"
    echo "eval \"\$(zoxide init --cmd cd zsh)\"" >> ~/.zshrc
  fi
fi

# eza
EZA=${EZA:-"false"}
if [ "$EZA" = "true" ]; then
  # Install eza
  sudo mkdir -p /etc/apt/keyrings
  wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
  echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
  sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
  sudo apt-get update
  sudo apt-get install -y eza
  # add eza to zshrc if available
  if [ -f ~/.zshrc ]; then
    echo "Adding eza to zshrc"
    echo "alias ls=\"eza\"" >> ~/.zshrc
    echo "alias ll=\"eza -l\"" >> ~/.zshrc
    echo "alias la=\"eza -la\"" >> ~/.zshrc
  fi
fi

# motd
MOTD=${MOTD:-"false"}
if [ "$MOTD" = "true" ]; then
  # Install motd.sh
  echo "Adding motd to zshrc"
  echo "source $(dirname $0)/.motd_gen.sh" >> /etc/motd
  # print motd on zsh startup
  echo "cat /etc/motd" >> ~/.zshrc
fi