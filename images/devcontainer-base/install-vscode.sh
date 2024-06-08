#!/usr/bin/env bash

CODE_BIN=${install_dir}/code/code
CODE_SERVER_BIN=${install_dir}/vscode-server/bin/code-server

# first make sure all the folders exist
mkdir -p $(dirname $CODE_BIN)
mkdir -p $(dirname $CODE_SERVER_BIN)

ARCH=$(uname -m)
case "$ARCH" in
  x86_64) ARCH="x64" ;;
  aarch64) ARCH="arm64" ;;
  *)
    echo "Unsupported architecture"
    exit 1
    ;;
esac

install_code() {
  output=$()
  if [ $? -ne 0 ]; then
    echo "Failed to install vscode-cli"
    exit 1
  else
    echo "vscode-cli installed at $${CODE_BIN}"
  fi
}

install_vscode_server() {
  HASH=$(curl -fsSL https://update.code.visualstudio.com/api/commits/stable/server-linux-$ARCH-web | cut -d '"' -f 2)
  output=$(curl -fsSL https://vscode.download.prss.microsoft.com/dbazure/download/stable/$HASH/vscode-server-linux-$ARCH-web.tar.gz | tar -xz -C ${install_dir}/vscode-server --strip-components 1)
  if [ $? -ne 0 ]; then
    echo "Failed to install vscode-server"
    exit 1
  else 
    echo "vscode-server installed at $${CODE_SERVER_BIN}"
  fi
}

if [ ! -x "$CODE_BIN" ]; then
  echo "vscode-cli not found, installing..."
  install_code
else
  echo "vscode-cli is already installed at $${CODE_BIN}"
fi

if [ ! -x "$CODE_SERVER_BIN" ]; then
  echo "vscode-server not found, installing..."
  install_vscode_server
else
  echo "vscode-server is already installed at $${CODE_SERVER_BIN}"
fi

settings_path=~/.vscode-server/data/Machine/settings.json
generated_settings_path=/vscode/settings/settings.json
# if generated settings file exists, copy it to the settings path
if [ -f $generated_settings_path ]; then
  echo "🔧 Applying custom settings..."
  cp $generated_settings_path $settings_path
fi

# read /vscode/settings/extensions.json and install extensions
# the file is a json array of extension ids
extensions_path=/vscode/settings/extensions.json
if [ -f $extensions_path ]; then
  extensions=$(cat $extensions_path | jq -r '.[]')
  for extension in $extensions; do
    echo "📦 Installing extension: $extension"
    if $${CODE_SERVER_BIN} --install-extension $extension --extensions-dir ~/.vscode-server/extensions --force > /dev/null; then
      echo "Extension $extension installed successfully"
    else
      echo "Failed to install extension $extension"
    fi
  done
else
  echo "No extensions to install"
fi

echo "👷 Running VS Code Web in the background..."
echo "Check logs at ${log_path}!"

COMMAND="$CODE_BIN serve-web --port ${port} --host 0.0.0.0 --accept-server-license-terms --without-connection-token --extensions-dir ~/.vscode-server/extensions --user-data-dir ~/.vscode-server/data/Machine --server-data-dir /vscode/server-data"

echo "Running command: $COMMAND"
VSCODE_KEYRING_PASS="vscode-keyring-pass"
# Run a dbus session, which unlocks the gnome-keyring and runs the VS Code Server inside of it
dbus-run-session -- sh -c "echo $VSCODE_KEYRING_PASS | gnome-keyring-daemon --unlock && $COMMAND > ${log_path} 2>&1 &"