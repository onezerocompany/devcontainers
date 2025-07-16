#!/bin/bash
set -e

# Update package list
apt-get update -y

# Install basic requirements
apt-get install -y curl wget software-properties-common

# Try to install apt-fast manually without PPA
echo "Attempting to install apt-fast..."
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
        echo "apt-fast installed successfully"
        APT_CMD="apt-fast"
    else
        echo "Failed to install aria2, falling back to apt-get"
        APT_CMD="apt-get"
    fi
else
    echo "Failed to download apt-fast, using standard apt-get"
    APT_CMD="apt-get"
fi

# Optionally try to add git PPA for newer git version (but don't fail if it doesn't work)
echo "Attempting to add git PPA for newer version..."
add-apt-repository -y ppa:git-core/ppa 2>/dev/null || echo "Could not add git PPA, will use default version"
apt-get update -y || true

# Split upgrade and install to avoid QEMU issues on ARM64
$APT_CMD upgrade -y || true

# Install packages in smaller groups to reduce memory pressure
# Group 1: Basic tools
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
    lsb-release

# Group 2: Build tools and libraries
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

# Group 3: Additional development tools
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

# Group 4: Supervisor and iptables
$APT_CMD install -y supervisor iptables
update-alternatives --set iptables /usr/sbin/iptables-legacy