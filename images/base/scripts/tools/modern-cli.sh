#!/bin/bash
# Install modern CLI tools (starship, zoxide, eza)
set -e

echo "🚀 Installing modern CLI tools..."

# Starship - Cross-shell prompt
echo "  ⭐ Installing starship prompt..."
curl -sS https://starship.rs/install.sh | sh -s -- -y

# Zoxide - Smarter cd command
echo "  📂 Installing zoxide (smart cd)..."
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

# Eza - Modern replacement for ls
echo "  📋 Installing eza (modern ls)..."
mkdir -p /etc/apt/keyrings
wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | tee /etc/apt/sources.list.d/gierens.list
chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
apt-get update
apt-get install -y eza