#!/bin/bash -e

INSTALL=${INSTALL:-"true"}
if [ "$INSTALL" = "false" ]; then
  echo "Skipping OnePassword CLI installation"
  exit 0
fi

USER=${USER:-"zero"}

ARCH=$(uname -m)
case $ARCH in
  x86_64)
    ARCH="amd64"
    ;;
  i*86)
    ARCH="386"
    ;;
  armv6*)
    ARCH="arm"
    ;;
  armv7*)
    ARCH="arm"
    ;;
  aarch64*)
    ARCH="arm64"
    ;;
  *)
    echo "Unsupported architecture: $ARCH"
    exit 1
    ;;
esac

latest_version=$(curl -s https://app-updates.agilebits.com/product_history/CLI2 | grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+' | head -n1)

wget "https://cache.agilebits.com/dist/1P/op2/pkg/$latest_version/op_linux_${ARCH}_$latest_version.zip" -O op.zip
unzip -d op op.zip
sudo mv op/op /usr/local/bin/
rm -r op.zip op
sudo groupadd -f onepassword-cli
sudo chgrp onepassword-cli /usr/local/bin/op
sudo chmod g+s /usr/local/bin/op

# Add user to onepassword-cli group
sudo usermod -aG onepassword-cli $USER