#!/bin/bash -e

USER=${USER:-"zero"}
VERSION=${VERSION:-"latest"}

# Install required packages
apt-get update -y
apt-get install \
          binutils \
          git \
          gnupg2 \
          libc6-dev \
          libcurl4-openssl-dev \
          libedit2 \
          libgcc-9-dev \
          libpython3.8 \
          libsqlite3-0 \
          libstdc++-9-dev \
          libxml2-dev \
          libz3-dev \
          pkg-config \
          tzdata \
          unzip \
          zlib1g-dev

# Setup keys
wget -q -O - https://swift.org/keys/all-keys.asc | gpg --import -
gpg --keyserver hkp://keyserver.ubuntu.com --refresh-keys Swift

# determine the latest version using github
if [ "$VERSION" = "latest" ]; then
    VERSION=$(curl -s https://api.github.com/repos/apple/swift/releases/latest | jq -r ".tag_name" | sed -n 's/^swift-\([0-9]*\.[0-9]*\)-RELEASE$/\1/p')
fi

echo "Installing Swift version: $VERSION"

if [ "$(uname -m)" = "aarch64" ]; then
    SWIFT_URL="https://download.swift.org/swift-5.10-release/ubuntu2204-aarch64/swift-5.10-RELEASE/swift-5.10-RELEASE-ubuntu22.04-aarch64.tar.gz"
else
    SWIFT_URL="https://download.swift.org/swift-5.10-release/ubuntu2204/swift-5.10-RELEASE/swift-5.10-RELEASE-ubuntu22.04.tar.gz"
fi

echo "Downloading Swift from: $SWIFT_URL"

wget -q -O /tmp/swift.tar.gz $SWIFT_URL
wget -q -O /tmp/swift.tar.gz.sig $SWIFT_URL.sig
gpg --verify /tmp/swift.tar.gz.sig
mkdir -p /etc/swift
tar -xzf /tmp/swift.tar.gz -C /etc/swift --strip-components=1

# Add Swift to PATH
echo "export PATH=\$PATH:/etc/swift/usr/bin" >> /home/$USER/.zshrc
echo "export PATH=\$PATH:/etc/swift/usr/bin" >> /home/$USER/.bashrc

# Cleanup
rm -rf /tmp/swift.tar.gz