#!/bin/bash -e

INSTALL=${INSTALL:-"true"}
VERSION=${VERSION:-"latest"}
USER=${USER:-"zero"}
AUTO_TRUST_WORKSPACE=${AUTOTRUST_WORKSPACE:-"false"}
TRUSTED_PATHS=${TRUSTED_PATHS:-""}
ZSHRC=${ZSHRC:-"$(su $USER -c 'echo $HOME')/.zshrc"}
USER_HOME=${USER_HOME:-"$(su $USER -c 'echo $HOME')"}

if [[ "$VERSION" = "none" || "$INSTALL" != "true" ]]; then
  echo "Skipping mise installation"
  exit 0
fi

# Install mise
echo "Installing mise..."
if [ "$VERSION" = "latest" ]; then
  # Install the latest version of mise
  su $USER -c "curl https://mise.run | sh"
else
  # Install a specific version of mise
  su $USER -c "curl https://mise.run | MISE_VERSION=\"v${VERSION}\" sh"
fi

# Add mise activation to zshrc
echo "Adding mise activation to zshrc"
echo "" >> $ZSHRC
echo "# mise activation" >> $ZSHRC
echo 'eval "$($HOME/.local/bin/mise activate zsh)"' >> $ZSHRC

# Configure auto-trust if enabled
if [ "$AUTO_TRUST_WORKSPACE" = "true" ] || [ -n "$TRUSTED_PATHS" ]; then
  echo "Configuring mise auto-trust..."
  
  # Build the trusted paths list
  TRUST_PATHS=""
  
  # Add workspace directory if auto-trust is enabled
  if [ "$AUTO_TRUST_WORKSPACE" = "true" ]; then
    TRUST_PATHS="/workspaces"
    echo "Auto-trusting workspace directory: /workspaces"
  fi
  
  # Add additional trusted paths
  if [ -n "$TRUSTED_PATHS" ]; then
    # Replace commas with colons for MISE_TRUSTED_CONFIG_PATHS format
    ADDITIONAL_PATHS=$(echo "$TRUSTED_PATHS" | sed 's/,/:/g')
    if [ -n "$TRUST_PATHS" ]; then
      TRUST_PATHS="${TRUST_PATHS}:${ADDITIONAL_PATHS}"
    else
      TRUST_PATHS="${ADDITIONAL_PATHS}"
    fi
    echo "Adding additional trusted paths: $ADDITIONAL_PATHS"
  fi
  
  # Export the trusted paths environment variable
  if [ -n "$TRUST_PATHS" ]; then
    echo "" >> $ZSHRC
    echo "# mise auto-trust configuration" >> $ZSHRC
    echo "export MISE_TRUSTED_CONFIG_PATHS=\"${TRUST_PATHS}\"" >> $ZSHRC
  fi
fi

# Create global mise config directory
su $USER -c "mkdir -p $USER_HOME/.config/mise"

echo "mise installation complete!"