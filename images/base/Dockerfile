FROM ubuntu:22.04

# Dotnet ENV
ENV \
    # Configure web servers to bind to port 80 when present
    ASPNETCORE_URLS=http://+:80 \
    # Enable detection of running in a container
    DOTNET_RUNNING_IN_CONTAINER=true

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y \
    && apt-get install -y software-properties-common \
    && add-apt-repository -y ppa:git-core/ppa \
    && apt-get update -y \
    && apt-get install -y --no-install-recommends curl wget sudo \
    && /bin/bash -c "$(curl -sL https://git.io/vokNn)"

RUN apt-get -y upgrade && \
    apt-get -y install \
    zsh git unzip zip tar xz-utils \
    jq ca-certificates lsb-release \
		# Build dependencies
    build-essential make cmake libglu1-mesa \
		software-properties-common \
		# Python dependencies
    python3 python3-pip python3-venv \
		# .NET dependencies
		libc6 \
		libgcc1 \
		libgssapi-krb5-2 \
		libicu70 \
		libssl3 \
		libstdc++6 \
		zlib1g \
		# DevContainer tools
    skopeo \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m zero && \
    echo "zero:zero" | chpasswd && adduser zero sudo && \
    echo "zero ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
    
RUN chsh -s /bin/zsh zero && \
    chown -R zero:zero /home/zero

USER zero
