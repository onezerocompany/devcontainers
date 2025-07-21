#!/bin/bash
set -e

echo "🦇 Installing bat (modern cat)..."
BAT_VERSION="0.24.0"
ARCH=$(dpkg --print-architecture)
case $ARCH in
    amd64) BAT_ARCH="x86_64" ;;
    arm64) BAT_ARCH="aarch64" ;;
    *) echo "Unsupported architecture for bat: $ARCH"; exit 1 ;;
esac
wget -q -O /tmp/bat.deb "https://github.com/sharkdp/bat/releases/download/v${BAT_VERSION}/bat_${BAT_VERSION}_${ARCH}.deb"
dpkg -i /tmp/bat.deb || apt-get install -f -y
rm -f /tmp/bat.deb