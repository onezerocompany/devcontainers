#!/bin/bash -e

USER=${USER:-"zero"}
USER_HOME="/home/$USER"
ZSHRC="$USER_HOME/.zshrc"

echo "Installing common utils"
echo "USER: $USER"
echo "USER_HOME: $USER_HOME"

apt-get update

# auto-cd
AUTO_CD=${AUTO_CD:-"false"}
if [ "$AUTO_CD" = "true" ]; then
  # add auto-cd to zshrc if available
  echo "setopt auto_cd" >> $ZSHRC
fi

# zoxide
ZOXIDE=${ZOXIDE:-"false"}
if [ "$ZOXIDE" = "true" ]; then
  # Install zoxide
  apt-get install -y fzf
  su $USER -c "curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash"
  # add zoxide to path
  echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> $ZSHRC
  # add zoxide to zshrc if available
  echo "eval \"\$(zoxide init --cmd cd zsh)\"" >> $ZSHRC
fi

# bat
BAT=${BAT:-"false"}
if [ "$BAT" = "true" ]; then
  # Install bat
  apt-get install -y bat
  # add bat to zshrc if available
  echo "alias cat=\"batcat\"" >> $ZSHRC
fi

# eza
EZA=${EZA:-"false"}
if [ "$EZA" = "true" ]; then
  # Install eza
  sudo mkdir -p /etc/apt/keyrings
  wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
  echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
  sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
  sudo apt update
  sudo apt install -y eza
  # add eza to zshrc if available
  if [ -f $ZSHRC ]; then
    echo "Adding eza to zshrc"
    echo "alias ls=\"eza\"" >> $ZSHRC
    echo "alias ll=\"eza -l\"" >> $ZSHRC
    echo "alias la=\"eza -la\"" >> $ZSHRC
  fi
fi

# tools
TOOLS=${TOOLS:-"false"}
if [ "$TOOLS" = "true" ]; then
  echo "Installing tools command"
  cp $(dirname $0)/tools.sh /usr/local/bin/tools
  chmod +x /usr/local/bin/tools
fi

# motd
MOTD=${MOTD:-"false"}
if [ "$MOTD" = "true" ]; then
  echo "Installing motd"
  $(dirname $0)/motd_gen.sh > /etc/motd || true
  chmod 644 /etc/motd
fi

# Install oh my posh
OHMYPOSH=${OHMYPOSH:-"false"}
if [ "$OHMYPOSH" = "true" ]; then
  curl -s https://ohmyposh.dev/install.sh | bash -s
  # Install onezero theme
  mkdir -p $USER_HOME/.config/posh
  # make sure config folder is owner by zero
  chown -R $USER:$USER $USER_HOME/.config
  chmod -R 755 $USER_HOME/.config
  cp $(dirname $0)/onezero.omp.json $USER_HOME/.config/posh/onezero.omp.json
  # add oh my posh to zshrc if available
  echo "eval \"\$(oh-my-posh --init --shell zsh --config $USER_HOME/.config/posh/onezero.omp.json)\"" >> $ZSHRC
fi