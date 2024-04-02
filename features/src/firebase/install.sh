#!/bin/bash -e

INSTALL=${INSTALL:-"true"}
USER=${USER:-"zero"}
if [ "$INSTALL" != "true" ]; then
  exit 0
fi

su $USER -c "curl -sL https://firebase.tools | bash"
