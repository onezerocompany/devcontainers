#!/bin/bash
set -e

# Update package list and install software-properties-common
apt-get update -y
apt-get install -y software-properties-common

# Add repositories
add-apt-repository -y ppa:git-core/ppa
add-apt-repository -y ppa:apt-fast/stable

# Update again after adding repositories
apt-get update -y
apt-get install -y apt-fast

# Split upgrade and install to avoid QEMU issues on ARM64
apt-get upgrade -y || true

# Install packages in smaller groups to reduce memory pressure
# Group 1: Basic tools
apt-get install -y \
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
apt-get install -y \
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
apt-get install -y \
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
apt-get install -y supervisor iptables
update-alternatives --set iptables /usr/sbin/iptables-legacy