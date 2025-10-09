#!/bin/bash
# Install basic development and CI/CD tools for GitHub Actions runner

set -e

echo "Installing basic development tools..."

export DEBIAN_FRONTEND=noninteractive

# Update package list
apt-get update -y

# Install all basic tools
apt-get install -y \
    acl \
    aria2 \
    autoconf \
    automake \
    binutils \
    bison \
    brotli \
    bzip2 \
    coreutils \
    curl \
    dbus \
    dnsutils \
    dpkg-dev \
    fakeroot \
    file \
    findutils \
    flex \
    fonts-noto-color-emoji \
    ftp \
    g++ \
    gcc \
    gnupg2 \
    haveged \
    iproute2 \
    iputils-ping \
    jq \
    libsqlite3-dev \
    libssl-dev \
    libtool \
    libyaml-dev \
    locales \
    lz4 \
    m4 \
    make \
    mediainfo \
    mercurial \
    net-tools \
    netcat-openbsd \
    openssh-client \
    p7zip-full \
    p7zip-rar \
    parallel \
    patchelf \
    pigz \
    pkg-config \
    pollinate \
    python-is-python3 \
    rpm \
    rsync \
    shellcheck \
    sphinxsearch \
    sqlite3 \
    ssh \
    sshpass \
    sudo \
    swig \
    systemd-coredump \
    tar \
    telnet \
    texinfo \
    time \
    tk \
    tree \
    tzdata \
    unzip \
    upx \
    wget \
    xvfb \
    xz-utils \
    zip \
    zsync

# Clean up
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "Basic development tools installation completed successfully!"
