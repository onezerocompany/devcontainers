#!/bin/bash -e

INSTALL=${INSTALL:-"true"}
USER=${USER:-"zero"}
if [ "$INSTALL" != "true" ]; then
  exit 0
fi

if [ "$(uname -m)" == "aarch64" ]; then
  echo "Firebase is not supported on arm64 yet."
  exit 0
fi

su $USER -c "curl -sL https://firebase.tools | bash"

# Pre-download the emulators
firebase setup:emulators:firestore
firebase setup:emulators:database
firebase setup:emulators:pubsub
firebase setup:emulators:storage
firebase setup:emulators:ui