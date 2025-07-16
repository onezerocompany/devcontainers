#!/bin/bash
set -e

# Update package list
apt-get update -y

# Install basic requirements
apt-get install -y curl wget software-properties-common

# Try to install apt-fast manually without PPA
echo "📦 Installing package manager optimizations..."
mkdir -p /etc/bash_completion.d
if wget -O /usr/local/sbin/apt-fast "https://raw.githubusercontent.com/ilikenwf/apt-fast/master/apt-fast" 2>/dev/null && \
    chmod +x /usr/local/sbin/apt-fast && \
    wget -O /etc/bash_completion.d/apt-fast "https://raw.githubusercontent.com/ilikenwf/apt-fast/master/completions/bash/apt-fast" 2>/dev/null; then
     # Create apt-fast configuration
     cat > /etc/apt-fast.conf << 'EOF'
# apt-fast configuration
_APTMGR=apt-get
DOWNLOADBEFORE=true
_MAXNUM=5
_MAXCONPERSRV=10
_SPLITCON=8
_MINSPLITSZ=1M
_PIECEALGO=default
DLLIST='/tmp/apt-fast.list'
_DOWNLOADER='aria2c --no-conf -c -j ${_MAXNUM} -x ${_MAXCONPERSRV} -s ${_SPLITCON} -i ${DLLIST} --min-split-size=${_MINSPLITSZ} --stream-piece-selector=${_PIECEALGO} --connect-timeout=60 --timeout=600 --max-connection-per-server=16'
APTCACHE=/var/cache/apt/apt-fast
EOF
     
     # Install aria2 for parallel downloads
     if apt-get install -y aria2; then
          echo "  ✅ apt-fast installed successfully."
          APT_CMD="apt-fast"
     else
          echo "  ⚠️ Failed to install aria2, falling back to apt-get."
          APT_CMD="apt-get"
     fi
else
     echo "  ⚠️ Failed to download apt-fast, using standard apt-get."
     APT_CMD="apt-get"
fi

# Optionally try to add git PPA for newer git version (but don't fail if it doesn't work)
echo "🔧 Adding package repositories..."
add-apt-repository -y ppa:git-core/ppa 2>/dev/null || echo "  ⚠️ Could not add git PPA, will use default version."
apt-get update -y || true

# Split upgrade and install to avoid QEMU issues on ARM64
echo "📦 Installing system packages..."
$APT_CMD upgrade -y || true

# Install packages in smaller groups to reduce memory pressure
echo "  📦 Installing basic tools..."
$APT_CMD install -y \
     curl \
     wget \
     sudo \
     gpg \
     nano \
     vim \
     zsh \
     git \
     zip unzip \
     tar xz-utils \
     jq \
     ca-certificates \
     lsb-release \
     bat \
     fzf \
     

echo "  🔨 Installing build tools and libraries..."
$APT_CMD install -y \
     build-essential \
     make \
     cmake \
     libglu1-mesa \
     libc6 libc6-dev \
     libgcc1 libgcc-9-dev \
     libgssapi-krb5-2 \
     libicu70 \
     libssl3 \
     libstdc++6 \
     zlib1g zlib1g-dev

echo "  🛠️ Installing additional development tools..."
$APT_CMD install -y \
     skopeo \
     binutils \
     gnupg2 \
     libcurl4-openssl-dev \
     libedit2 \
     libpython3.8 \
     libsqlite3-0 \
     libstdc++-9-dev \
     libxml2-dev \
     libz3-dev \
     pkg-config \
     tzdata \
     gnome-keyring \
     python3-minimal

echo "  🔧 Installing supervisor and iptables..."
$APT_CMD install -y supervisor iptables
update-alternatives --set iptables /usr/sbin/iptables-legacy

# Install modern CLI tools
echo "🚀 Installing modern CLI tools..."

echo "  ⭐ Installing starship prompt..."
curl -sS https://starship.rs/install.sh | sh -s -- -y

echo "  📂 Installing zoxide (smart cd)..."
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh

echo "  📋 Installing eza (better ls)..."
mkdir -p /etc/apt/keyrings
wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | tee /etc/apt/sources.list.d/gierens.list
chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
apt-get update
apt-get install -y eza