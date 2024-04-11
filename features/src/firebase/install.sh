#!/bin/bash -e

INSTALL=${INSTALL:-"true"}
USER=${USER:-"zero"}
if [ "$INSTALL" != "true" ]; then
  exit 0
fi

# in case we are on arm64, fail gracefully
if [ "$(uname -m)" == "aarch64" ]; then
  echo "Flutter is not supported on arm64 yet."
  exit 0
fi

su $USER -c "curl -sL https://firebase.tools | bash"
