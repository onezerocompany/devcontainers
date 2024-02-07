#!/usr/bin/env sh

APP_DIR=/usr/local/bin

# Determine if vscode-cli is already installed
BIN_PATH=$(which code)

# if not installed, install it
if [ -z "${BIN_PATH}" ]; then
  echo "vscode-cli not found, installing..."

  arch=$(uname -m)
  case $arch in
    x64) arch="x64" ;;
    x86_64) arch="x64" ;;
    aarch64) arch="arm64" ;;
    arm64) arch="arm64" ;;
    *) echo "Unsupported architecture: $arch"; exit 1 ;;
  esac

  mkdir -p ${APP_DIR}

  output=$(curl -Lk "https://code.visualstudio.com/sha/download?build=stable&os=cli-alpine-$arch" --output vscode_cli.tar.gz && tar -xf vscode_cli.tar.gz -C ${APP_DIR} && rm vscode_cli.tar.gz)

  if [ $? -ne 0 ]; then
    echo "Failed to install vscode-cli: $output"
    exit 1
  fi

  BIN_PATH=$APP_DIR/code

else
  echo "vscode-cli is already installed at ${BIN_PATH}"
fi

# Install into 