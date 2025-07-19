#!/bin/bash

# Define required functions directly
add_to_path() {
    local dir="$1"
    if [ -d "$dir" ] && [[ ":$PATH:" != *":$dir:"* ]]; then
        export PATH="$dir:$PATH"
    fi
}

configure_path() {
    local path_line="export PATH=\"\$HOME/.local/bin:\$PATH\""
    
    # Add to bash configs
    if [ -f "$HOME/.bashrc" ]; then
        grep -qF "$path_line" "$HOME/.bashrc" || echo "$path_line" >> "$HOME/.bashrc"
    fi
    
    # Add to zsh configs
    if [ -f "$HOME/.zshenv" ]; then
        grep -qF "$path_line" "$HOME/.zshenv" || echo "$path_line" >> "$HOME/.zshenv"
    fi
}

wait_for_docker() {
    # Wait for Docker daemon to be available
    local max_tries=30
    local wait_time=1
    local count=0
    
    while ! docker version &>/dev/null; do
        count=$((count + 1))
        if [ $count -ge $max_tries ]; then
            echo "Docker daemon not available after ${max_tries} attempts"
            return 1
        fi
        sleep $wait_time
    done
}

USER=${USER:-zero}
INSTALL_DIR=${INSTALL_DIR:-/home/${USER}/.vscode-install}
WORKSPACE_DIR=${WORKSPACE_DIR:-/workspaces}
VSCODE_SERVER_DIR=${VSCODE_SERVER_DIR:-~/.vscode-server}
EXTENSION_DIR=${EXTENSION_DIR:-~/.vscode-server/extensions}
VSCODE_PORT=${VSCODE_PORT:-13338}
VSCODE_KEYRING_PASS=${VSCODE_KEYRING_PASS:-"vscode-keyring-pass"}
VSCODE_LOG_PATH=${VSCODE_LOG_PATH:-/tmp/vscode-server.log}

detect_arch() {
  case "$(uname -m)" in
    x86_64) echo "x64" ;;
    armv8*) echo "arm64" ;;
    aarch64) echo "arm64" ;;
    arm64) echo "arm64" ;;
    *) echo "unsupported" ;;
  esac
}

arch=$(detect_arch)
if [ "$arch" == "unsupported" ]; then
  echo "  ❌ Unsupported architecture."
  exit 1
fi

# wait_for_docker is available from common-utils.sh

install() {
  echo "Installing vscode and vscode-web tools for $arch..."

  mkdir -p $INSTALL_DIR/code

  # Install code command
  curl -fsSL "https://code.visualstudio.com/sha/download?build=stable&os=cli-alpine-$arch" | tar -xz -C $INSTALL_DIR/code

  if [ $? -ne 0 ]; then
    echo "  ❌ Failed to install vscode-cli."
    exit 1
  else
    echo "  ✅ vscode-cli installed at $INSTALL_DIR/code."
  fi

  # Add code directory to PATH
  add_to_path "$INSTALL_DIR/code"
  configure_path  # This ensures .local/bin is in PATH for all shells

  mkdir -p $INSTALL_DIR/vscode-server

  # Install code-server
  local hash=$(curl -fsSL https://update.code.visualstudio.com/api/commits/stable/server-linux-$arch-web | cut -d '"' -f 2)
  curl -fsSL https://vscode.download.prss.microsoft.com/dbazure/download/stable/$hash/vscode-server-linux-$arch-web.tar.gz | tar -xz -C $INSTALL_DIR/vscode-server --strip-components 1

  if [ $? -ne 0 ]; then
    echo "  ❌ Failed to install vscode-server."
    exit 1
  else
    echo "  ✅ vscode-server installed at $INSTALL_DIR/vscode-server."
  fi

  # Add vscode-server bin directory to PATH
  add_to_path "$INSTALL_DIR/vscode-server/bin"

}


setup() {
  # Wait for Docker to start if needed
  if [ -S "/var/run/docker.sock" ]; then
    wait_for_docker
  fi

  # Wait for workspace to be mounted
  while [ ! -d $WORKSPACE_DIR ]; do
    sleep 1
  done

  # Generate the manifest
  manifest=$(devcontainer read-configuration --workspace-folder $WORKSPACE_DIR --include-merged-configuration)
  extensions_json=$(echo $manifest | jq '[.mergedConfiguration.customizations.vscode[].extensions] | map(select(. != null)) | add | unique')
  settings_json=$(echo $manifest | jq '[.mergedConfiguration.customizations.vscode[].settings] | map(select(. != null)) | add')
  
  extensions=$(echo $extensions_json | jq -r '.[]')
  for extension in $extensions; do
    echo "  Installing extension: $extension..."
    if $INSTALL_DIR/vscode-server/bin/code-server --install-extension $extension --extensions-dir $VSCODE_SERVER_DIR/extensions --force > /dev/null; then
      echo "    ✅ Extension $extension installed successfully."
    else
      echo "    ❌ Failed to install extension $extension."
    fi
  done

  if [ -n "$settings_json" ]; then
    echo "  Applying settings..."
    echo $settings_json > $VSCODE_SERVER_DIR/data/Machine/settings.json
  fi
}


start() {
  COMMAND="$INSTALL_DIR/code/code serve-web --port ${VSCODE_PORT} --host 0.0.0.0 --accept-server-license-terms --without-connection-token --extensions-dir $EXTENSION_DIR --user-data-dir $VSCODE_SERVER_DIR/data/Machine --server-data-dir $VSCODE_SERVER_DIR/server"
  
  # Run a dbus session, which unlocks the gnome-keyring and runs the VS Code Server inside of it
  dbus-run-session -- sh -c "echo $VSCODE_KEYRING_PASS | gnome-keyring-daemon --unlock && $COMMAND > $VSCODE_LOG_PATH 2>&1 &"
}

# Check the command line arguments
case "$1" in
  install) install ;;
  setup) setup ;;
  start) start ;;
  *) echo "Usage: vscode-kit {install|setup|start}" ;;
esac