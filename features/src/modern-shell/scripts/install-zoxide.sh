#!/bin/bash
set -e

echo "📂 Installing zoxide (smart cd)..."
ZOXIDE_VERSION="0.9.6"
ARCH=$(dpkg --print-architecture)
case $ARCH in
    amd64) ZOXIDE_ARCH="x86_64" ;;
    arm64) ZOXIDE_ARCH="aarch64" ;;
    *) echo "Unsupported architecture for zoxide: $ARCH"; exit 1 ;;
esac
wget -q -O /tmp/zoxide.tar.gz "https://github.com/ajeetdsouza/zoxide/releases/download/v${ZOXIDE_VERSION}/zoxide-${ZOXIDE_VERSION}-${ZOXIDE_ARCH}-unknown-linux-musl.tar.gz"
tar -xzf /tmp/zoxide.tar.gz -C /tmp
mv /tmp/zoxide /usr/local/bin/zoxide
chmod +x /usr/local/bin/zoxide
rm -f /tmp/zoxide.tar.gz