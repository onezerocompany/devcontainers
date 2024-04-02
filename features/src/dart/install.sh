#!/bin/bash -e

INSTALL=${INSTALL:-"true"}
USER=${USER:-"zero"}
DART_DIR=${DART_DIR:-"/usr/local/lib/dart-sdk"}
CHANNEL_OR_VERSION=${VERSION:-"stable"}

if [[ "$CHANNEL_OR_VERSION" = "none" || "$INSTALL" != "true" ]]; then
  echo "Skipping Dart SDK installation"
  exit 0
fi

function arch() {
  case $(dpkg --print-architecture) in
    amd64) echo "x64";;
    arm64) echo "arm64";;
    armhf) echo "arm";;
    *) echo "unknown";;
  esac
}

function platform() {
  case $(uname -s) in
    Linux) echo "linux";;
    Darwin) echo "macos";;
    *) echo "unknown";;
  esac
}

arch=$(arch)
platform=$(platform)

if [[ "$arch" == "unknown" || "$platform" == "unknown" ]]; then
  echo "Unknown architecture or platform. Cannot install Dart SDK."
  exit 1
fi

function download_dart_sdk() {
  version_or_channel="$1"

  # Validate the provided channel
  if [[ "$version_or_channel" != "stable" && "$version_or_channel" != "dev" && "$version_or_channel" != "beta" && ! "$version_or_channel" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Invalid channel: $version_or_channel. Valid options: stable, dev, beta, or x.y.z"
    return 1
  fi

  # Construct the download URL based on the channel or version
  if [[ "$version_or_channel" == "stable" || "$version_or_channel" == "dev" || "$version_or_channel" == "beta" ]]; then
    DOWNLOAD_URL="https://storage.googleapis.com/dart-archive/channels/$version_or_channel/release/latest/sdk/dartsdk-$platform-$arch-release.zip"
  else
    DOWNLOAD_URL="https://storage.googleapis.com/dart-archive/channels/stable/release/$version_or_channel/sdk/dartsdk-$platform-$arch-release.zip"
  fi

  # Download the SDK archive
  echo "Downloading Dart SDK from: $DOWNLOAD_URL"
  if ! wget -q -O "/tmp/dart-sdk.zip" "$DOWNLOAD_URL"; then
    echo "Download failed. Please check your network connection or the provided channel/version."
    return 1
  fi

  echo "Dart SDK downloaded to /tmp/dart-sdk.zip"
}

mkdir -p $DART_DIR
chmod -R 777 $DART_DIR

download_dart_sdk $CHANNEL_OR_VERSION

# Extract Dart
unzip -q /tmp/dart-sdk.zip -d /usr/local/lib

# Add Dart to PATH
echo "export PATH="/usr/local/lib/dart-sdk/bin:$PATH"" >> /home/$USER/.zshrc
echo "export PATH="/usr/local/lib/dart-sdk/bin:$PATH"" >> /home/$USER/.bashrc