#!/bin/bash -e

USERNAME="${USERNAME:-zero}"

# Install packages required for sandbox functionality
echo "Installing sandbox packages..."
apt-get update

# Use apt-fast - it must be available
APT_CMD="apt-fast"

# Install Blocky - a lightweight DNS proxy with filtering capabilities
echo "  Installing Blocky DNS proxy..."

# Create blocky user and directories
adduser --system --no-create-home --group blocky
mkdir -p /etc/blocky /var/lib/blocky /var/log/services/blocky
chown -R blocky:blocky /etc/blocky /var/lib/blocky /var/log/services/blocky

# Download Blocky binary (latest stable)
BLOCKY_VERSION="v0.26.2"
ARCH=$(dpkg --print-architecture)
case $ARCH in
    amd64) BLOCKY_ARCH="x86_64" ;;
    arm64) BLOCKY_ARCH="arm64" ;;
    *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

# Download and extract Blocky
BLOCKY_TARBALL="blocky_${BLOCKY_VERSION}_Linux_${BLOCKY_ARCH}.tar.gz"
BLOCKY_URL="https://github.com/0xERR0R/blocky/releases/download/${BLOCKY_VERSION}/${BLOCKY_TARBALL}"

echo "Downloading Blocky from: ${BLOCKY_URL}"
wget -O /tmp/blocky.tar.gz "${BLOCKY_URL}"

# Extract blocky binary from tarball
tar -xzf /tmp/blocky.tar.gz -C /usr/local/bin blocky
chmod +x /usr/local/bin/blocky
rm -f /tmp/blocky.tar.gz

# Set capability to allow blocky to bind to port 53
setcap 'cap_net_bind_service=+ep' /usr/local/bin/blocky

# Copy s6-overlay service definitions for blocky
# (The actual service definitions are copied during Docker build)

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