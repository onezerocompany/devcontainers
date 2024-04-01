#!/bin/bash -e

USER=${USER:-"zero"}
FLUTTER_DIR=${FLUTTER_DIR:-"/opt/flutter"}
CHANNEL_OR_VERSION=${VERSION:-"stable"}

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
    if ! wget -q --show-progress -O "/tmp/flutter_linux.tar.xz" "$DOWNLOAD_URL"; then
        echo "Download failed. Please check your network connection or the provided channel/version."
        return 1
    fi

    echo "Flutter SDK downloaded to /tmp/flutter_linux.tar.xz"
}

mkdir -p $FLUTTER_DIR
chmod -R 777 $FLUTTER_DIR

apt-get update -y 
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