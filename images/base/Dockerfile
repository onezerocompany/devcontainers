# Base stage with common dependencies
FROM ubuntu:22.04 AS base

# Build arguments
ARG USERNAME=zero
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Environment variables
ENV ASPNETCORE_URLS=http://+:80
ENV DOTNET_RUNNING_IN_CONTAINER=true
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV HOME=/home/$USERNAME
ENV MISE_CACHE_DIR=$HOME/.cache/mise
ENV MISE_DATA_DIR=$HOME/.local/share/mise
ENV PATH="$HOME/.local/bin:${PATH}"
ENV MISE_TRUSTED_CONFIG_PATHS="/"
ENV MISE_YES=1
ENV SHELL=/bin/zsh

# Copy and run package installation script
COPY scripts/install-packages.sh /tmp/
RUN chmod +x /tmp/install-packages.sh && \
    /tmp/install-packages.sh && \
    rm /tmp/install-packages.sh

# Install s6-overlay
ARG S6_OVERLAY_VERSION=3.1.6.2
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
RUN apt-get update && apt-get install -y --no-install-recommends xz-utils && \
    tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz && \
    rm /tmp/s6-overlay-noarch.tar.xz && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Add architecture-specific s6-overlay
RUN ARCH=$(dpkg --print-architecture) && \
    if [ "$ARCH" = "amd64" ]; then S6_ARCH="x86_64"; \
    elif [ "$ARCH" = "arm64" ]; then S6_ARCH="aarch64"; \
    else echo "Unsupported architecture: $ARCH" && exit 1; fi && \
    curl -fsSL "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${S6_ARCH}.tar.xz" | tar -C / -Jx

# Create user with configurable name
RUN groupadd --gid $USER_GID $USERNAME && \
    useradd --uid $USER_UID --gid $USER_GID -m -s /bin/zsh $USERNAME && \
    echo "$USERNAME ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
    
# Set up shell configurations for both bash and zsh
COPY scripts/configure-shells.sh scripts/common-utils.sh starship.toml /tmp/
RUN chmod +x /tmp/configure-shells.sh && \
    /tmp/configure-shells.sh $USERNAME && \
    rm /tmp/configure-shells.sh /tmp/common-utils.sh

# Create necessary directories for the user before switching
RUN mkdir -p /home/$USERNAME/.local/bin && \
    mkdir -p /home/$USERNAME/.cache && \
    mkdir -p /home/$USERNAME/.local/share && \
    chown -R $USERNAME:$USERNAME /home/$USERNAME

# Copy unified entrypoint as root
COPY scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Create s6-overlay service directories
RUN mkdir -p /etc/s6-overlay/s6-rc.d

WORKDIR /home/$USERNAME
USER $USERNAME

# Install mise as non-root user
# Download directly from GitHub releases to avoid mise.run issues
RUN mkdir -p ~/.local/bin && \
    ARCH=$(dpkg --print-architecture) && \
    if [ "$ARCH" = "amd64" ]; then ARCH="x64"; fi && \
    if [ "$ARCH" = "arm64" ]; then ARCH="arm64"; fi && \
    MISE_VERSION=$(curl -s https://api.github.com/repos/jdx/mise/releases/latest | grep '"tag_name"' | cut -d'"' -f4) && \
    echo "Installing mise ${MISE_VERSION} for ${ARCH}..." && \
    curl -fsSL "https://github.com/jdx/mise/releases/download/${MISE_VERSION}/mise-${MISE_VERSION}-linux-${ARCH}" -o ~/.local/bin/mise && \
    chmod +x ~/.local/bin/mise && \
    ~/.local/bin/mise --version

# Setup node lts using mise global
RUN mise use -g node@lts

# Create mise cache directories
RUN mkdir -p ~/.cache/mise && \
    mkdir -p ~/.local/share/mise

# Copy mise configuration
COPY --chown=$USERNAME:$USERNAME global-mise.toml /home/$USERNAME/.mise.toml

# Install tools using mise configuration
# Install mise tools
RUN mise install

# Copy starship configuration after mise has installed starship
COPY --chown=$USERNAME:$USERNAME starship.toml /home/$USERNAME/.config/starship.toml

RUN touch ~/.sudo_as_admin_successful

# Test stage for standard variant
FROM base AS test-standard
USER root
COPY tests/ /tests/
RUN chmod +x /tests/test.sh /tests/test-s6-overlay.sh || true
USER $USERNAME
WORKDIR /home/$USERNAME
RUN /tests/test.sh

# Standard stage - no Docker-in-Docker (clean, inherits from base)
FROM base AS standard
# Configure s6-overlay following best practices
ENV S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0
ENV S6_VERBOSITY=1
ENV S6_STAGE2_HOOK=""
ENTRYPOINT ["/init", "/usr/local/bin/entrypoint.sh"]
CMD []

# Pre-DIND stage with Docker setup
FROM base AS dind-setup

USER root

# Copy and install Docker
COPY dind/install-docker.sh /tmp/
RUN bash /tmp/install-docker.sh && rm /tmp/install-docker.sh

# Copy Docker-related files
COPY dind/modprobe /usr/local/bin/ 
RUN chmod +x /usr/local/bin/modprobe

# Copy s6-overlay service definitions
COPY dind/s6-overlay/ /etc/s6-overlay/

# Create Docker volume
VOLUME /var/lib/docker

# Switch back to the configured user
USER $USERNAME

# Test stage for DIND variant
FROM dind-setup AS test-dind
USER root
COPY tests/ /tests/
RUN chmod +x /tests/test.sh /tests/test-s6-overlay.sh || true
USER $USERNAME
WORKDIR /home/$USERNAME
RUN /tests/test.sh

# Docker-in-Docker stage (clean, inherits from dind-setup)
FROM dind-setup AS dind
# Configure s6-overlay following best practices
ENV S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0
ENV S6_VERBOSITY=1
ENV S6_STAGE2_HOOK=""
ENTRYPOINT ["/init", "/usr/local/bin/entrypoint.sh"]
CMD []