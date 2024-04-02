#!/bin/bash -e

INSTALL=${INSTALL:-"true"}
USER=${USER:-"zero"}
FLUTTER_DIR=${FLUTTER_DIR:-"/opt/flutter"}
CHANNEL_OR_VERSION=${VERSION:-"stable"}
INSTALL_FVM=${INSTALL_FVM:-"true"}
FVM_DIR=${FVM_DIR:-"/etc/fvm"}

if [ "$INSTALL" != "true" ]; then
  echo "Skipping Flutter SDK installation"
  exit 0
fi

# in case we are on arm64, fail gracefully
if [ "$(uname -m)" == "aarch64" ]; then
  echo "Flutter is not supported on arm64 yet."
  exit 0
fi

function download_flutter_sdk() {
    channel="$1"

    # Validate the provided channel
    if [[ "$channel" != "stable" && "$channel" != "dev" && "$channel" != "beta" && ! "$channel" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Invalid channel: $channel. Valid options: stable, dev, beta, or x.y.z"
        return 1
    fi

    local releases=$(curl -s "https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json")
    local base_url=$(echo $releases | jq -r ".base_url")

    # Construct the download URL based on the channel or version
    if [[ "$channel" == "stable" || "$channel" == "dev" || "$channel" == "beta" ]]; then
      local hash=$(echo $releases | jq -r ".current_release.$channel")
      local release=$(echo $releases | jq -r ".releases[] | select(.hash == \"$hash\")")
      local archive=$(echo $release | jq -r ".archive")
      DOWNLOAD_URL="$base_url/$archive"
    else
      DOWNLOAD_URL="$base_url/stable/linux/flutter_linux_$channel.tar.xz"
    fi

    # Download the SDK archive
    echo "Downloading Flutter SDK from: $DOWNLOAD_URL"
    if ! wget -q -O "/tmp/flutter_linux.tar.xz" "$DOWNLOAD_URL"; then
        echo "Download failed. Please check your network connection or the provided channel/version."
        return 1
    fi

    echo "Flutter SDK downloaded to /tmp/flutter_linux.tar.xz"
}

mkdir -p $FLUTTER_DIR
chmod -R 777 $FLUTTER_DIR

# apt-get update -y 
apt-get install -y \
  curl git unzip xz-utils \
  zip libglu1-mesa \
  clang cmake git \
  ninja-build pkg-config \
  libgtk-3-dev liblzma-dev \
  libstdc++-12-dev

download_flutter_sdk $CHANNEL_OR_VERSION

# Extract Flutter
tar xf /tmp/flutter_linux.tar.xz -C /opt
chown -R $USER:$USER $FLUTTER_DIR

# Add Flutter to PATH
echo "export PATH=\$PATH:$FLUTTER_DIR/bin" >> /home/$USER/.zshrc
echo "export PATH=\$PATH:$FLUTTER_DIR/bin" >> /home/$USER/.bashrc

# Install FVM
if [ "$INSTALL_FVM" == "true" ]; then

  # Detect OS and architecture
  OS="$(uname -s)"
  ARCH="$(uname -m)"

  # Map to FVM naming
  case "$OS" in
    Linux*)  OS='linux' ;;
    Darwin*) OS='macos' ;;
    *)       log_message "Unsupported OS"; exit 1 ;;
  esac

  case "$ARCH" in
    x86_64)  ARCH='x64' ;;
    arm64)   ARCH='arm64' ;;
    armv7l)  ARCH='arm' ;;
    *)       log_message "Unsupported architecture"; exit 1 ;;
  esac

  # Define the URL of the FVM binary
  FVM_VERSION=$(curl -s https://api.github.com/repos/leoafarias/fvm/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
  if [ -z "$FVM_VERSION" ]; then
      echo "Failed to fetch latest FVM version."
  fi

  echo "Installing FVM version $FVM_VERSION."
  mkdir -p "$FVM_DIR" 

  # Download FVM
  URL="https://github.com/leoafarias/fvm/releases/download/$FVM_VERSION/fvm-$FVM_VERSION-$OS-$ARCH.tar.gz"
  curl -L "$URL" -o fvm.tar.gz
  tar -xzf fvm.tar.gz -C "$FVM_DIR"
  rm -f fvm.tar.gz

  FMV_DIR_BIN="$FVM_DIR/bin"
  mv "$FVM_DIR/fvm" "$FMV_DIR_BIN"

  # add fvm to PATH
  echo "export PATH=\$PATH:$FMV_DIR_BIN" >> /home/$USER/.zshrc
  echo "export PATH=\$PATH:$FMV_DIR_BIN" >> /home/$USER/.bashrc
  
  # setup f -> fvm flutter
  echo "alias f='fvm flutter'" >> /home/$USER/.zshrc
  echo "alias f='fvm flutter'" >> /home/$USER/.bashrc

  # setup d -> fvm dart
  echo "alias d='fvm dart'" >> /home/$USER/.zshrc
  echo "alias d='fvm dart'" >> /home/$USER/.bashrc
fi

# add alias 'devices' for 'flutter devices --show-web-server-device'
echo "alias devices='flutter devices --show-web-server-device'" >> /home/$USER/.zshrc
echo "alias devices='flutter devices --show-web-server-device'" >> /home/$USER/.bashrc