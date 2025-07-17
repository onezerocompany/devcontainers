#!/bin/bash

set -e

echo "Setting up DNS-based domain filtering..."

# Check if running in container
if [ ! -f /.dockerenv ]; then
    echo "  Warning: Not running in a container, skipping DNS filter setup."
    exit 0
fi

# Install Blocky - a lightweight DNS proxy with filtering capabilities
echo "  Installing Blocky DNS proxy..."

# Create blocky user and directories
adduser --system --no-create-home --group blocky || true
mkdir -p /etc/blocky /var/lib/blocky
chown -R blocky:blocky /etc/blocky /var/lib/blocky

# Download Blocky binary (latest stable)
BLOCKY_VERSION="v0.24"
ARCH=$(dpkg --print-architecture)
case $ARCH in
    amd64) BLOCKY_ARCH="x86_64" ;;
    arm64) BLOCKY_ARCH="aarch64" ;;
    *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

wget -q -O /usr/local/bin/blocky \
    "https://github.com/0xERR0R/blocky/releases/download/${BLOCKY_VERSION}/blocky_${BLOCKY_VERSION}_Linux_${BLOCKY_ARCH}"
chmod +x /usr/local/bin/blocky

# Create systemd service (or supervisor config for containers)
cat > /etc/systemd/system/blocky.service <<'EOF'
[Unit]
Description=Blocky DNS Proxy
After=network.target

[Service]
Type=simple
User=blocky
Group=blocky
ExecStart=/usr/local/bin/blocky --config /etc/blocky/config.yml
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

echo "  ✓ Blocky DNS proxy installed"