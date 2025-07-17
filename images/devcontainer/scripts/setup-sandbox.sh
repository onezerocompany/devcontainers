#!/bin/bash -e

USERNAME="${USERNAME:-zero}"

# Install packages required for sandbox functionality
echo "Installing sandbox packages..."
apt-get update

# Use apt-fast if available, otherwise fall back to apt-get
if command -v apt-fast >/dev/null 2>&1; then
    APT_CMD="apt-fast"
else
    APT_CMD="apt-get"
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

# Create directory for scripts
mkdir -p /usr/local/share/sandbox

# Add sudoers entries for sandbox operations
cat > /etc/sudoers.d/sandbox << EOF
# Sandbox state management
${USERNAME} ALL=(ALL) NOPASSWD: /bin/mkdir -p /var/lib/devcontainer-sandbox
${USERNAME} ALL=(ALL) NOPASSWD: /bin/chmod 755 /var/lib/devcontainer-sandbox
${USERNAME} ALL=(ALL) NOPASSWD: /usr/bin/tee /var/lib/devcontainer-sandbox/*
${USERNAME} ALL=(ALL) NOPASSWD: /bin/chmod 444 /var/lib/devcontainer-sandbox/*
EOF

chmod 0440 /etc/sudoers.d/sandbox

echo "
✓ Sandbox setup complete"