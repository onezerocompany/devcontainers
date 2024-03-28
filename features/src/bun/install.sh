#!/bin/bash -e

VERSION=${VERSION:-"latest"}

if [ "$VERSION" = "latest" ]; then
  # Install the latest version of bun
  curl -fsSL https://bun.sh/install | bash
else
  # Install a specific version of bun
  curl -fsSL https://bun.sh/install | bash -s "bun-v${VERSION}"
fi

# add bun to zshrc if available
if [ -f ~/.zshrc ]; then
  echo "Adding bun to zshrc"
  echo "export PATH=\"\$HOME/.bun/bin:\$PATH\"" >> ~/.zshrc
fi