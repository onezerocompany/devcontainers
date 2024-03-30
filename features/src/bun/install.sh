#!/bin/bash -e

VERSION=${VERSION:-"latest"}
USER=${USER:-"zero"}
ZSHRC=${ZSHRC:-"$(su $USER -c 'echo $HOME')/.zshrc"}

if [ "$VERSION" = "latest" ]; then
  # Install the latest version of bun
  su $USER -c "curl -fsSL https://bun.sh/install | bash"
else
  # Install a specific version of bun
  su $USER -c "curl -fsSL https://bun.sh/install | bash -s \"bun-v${VERSION}\""
fi

# add bun to zshrc if available
echo "Adding bun to zshrc"
echo "export PATH=\"\$HOME/.bun/bin:\$PATH\"" >> $ZSHRC