# Base stage with common dependencies
FROM buildpack-deps:bookworm AS base

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

# System preparation
COPY scripts/system/system-prep.sh /tmp/
RUN chmod +x /tmp/system-prep.sh && /tmp/system-prep.sh && rm /tmp/system-prep.sh

# Install apt-fast for faster package downloads
COPY scripts/system/apt-fast.sh /tmp/
RUN chmod +x /tmp/apt-fast.sh && /tmp/apt-fast.sh && rm /tmp/apt-fast.sh

# System upgrade
COPY scripts/system/system-upgrade.sh /tmp/
RUN chmod +x /tmp/system-upgrade.sh && APT_CMD=apt-fast /tmp/system-upgrade.sh && rm /tmp/system-upgrade.sh

# Core utilities and editors
COPY scripts/tools/core-utilities.sh /tmp/
RUN chmod +x /tmp/core-utilities.sh && APT_CMD=apt-fast /tmp/core-utilities.sh && rm /tmp/core-utilities.sh

# Build tools and libraries
COPY scripts/development/build-tools.sh /tmp/
RUN chmod +x /tmp/build-tools.sh && APT_CMD=apt-fast /tmp/build-tools.sh && rm /tmp/build-tools.sh

# Development tools
COPY scripts/development/dev-tools.sh /tmp/
RUN chmod +x /tmp/dev-tools.sh && APT_CMD=apt-fast /tmp/dev-tools.sh && rm /tmp/dev-tools.sh



# Cleanup
COPY scripts/system/cleanup.sh /tmp/
RUN chmod +x /tmp/cleanup.sh && /tmp/cleanup.sh && rm /tmp/cleanup.sh


# Create user with configurable name
RUN groupadd --gid $USER_GID $USERNAME && \
    useradd --uid $USER_UID --gid $USER_GID -m -s /bin/bash $USERNAME && \
    echo "$USERNAME ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
    

# Create necessary directories for the user before switching
RUN mkdir -p /home/$USERNAME/.local/bin && \
    mkdir -p /home/$USERNAME/.cache && \
    mkdir -p /home/$USERNAME/.local/share && \
    chown -R $USERNAME:$USERNAME /home/$USERNAME

# Copy unified entrypoint as root
COPY scripts/shell/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /home/$USERNAME
USER $USERNAME

# Install mise as non-root user
# Download directly from GitHub releases to avoid mise.run issues
RUN mkdir -p ~/.local/bin && \
    ARCH=$(dpkg --print-architecture) && \
    if [ "$ARCH" = "amd64" ]; then ARCH="x64"; fi && \
    if [ "$ARCH" = "arm64" ]; then ARCH="arm64"; fi && \
    MISE_VERSION=$(curl -s https://api.github.com/repos/jdx/mise/releases/latest | jq -r '.tag_name') && \
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
COPY --chown=$USERNAME:$USERNAME configs/global-mise.toml /home/$USERNAME/.mise.toml

# Install tools using mise configuration
# Install mise tools
RUN mise install


RUN touch ~/.sudo_as_admin_successful

# Standard stage - no Docker-in-Docker (clean, inherits from base)
FROM base AS standard
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD []

