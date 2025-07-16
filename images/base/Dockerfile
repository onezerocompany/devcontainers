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

# Copy unified entrypoint and common utilities as root
COPY scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY scripts/common-utils.sh /usr/local/bin/common-utils.sh
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/common-utils.sh

WORKDIR /home/$USERNAME
USER $USERNAME

# Install mise as non-root user
RUN curl -fsSL https://mise.run | sh

# Create mise cache directories
RUN mkdir -p ~/.cache/mise && \
    mkdir -p ~/.local/share/mise

# Note: We don't declare VOLUME here as it causes issues with pre-installed tools
# The devcontainer can mount these as volumes if needed for caching

# Copy mise configuration
COPY --chown=$USERNAME:$USERNAME global-mise.toml /home/$USERNAME/.mise.toml

# Install tools using mise configuration
# Add retry logic for mise install to handle network timeouts
RUN for i in 1 2 3; do \
        echo "Attempt $i: Installing mise tools..." && \
        mise install && break || \
        (echo "Failed attempt $i, retrying in 5 seconds..." && sleep 5); \
    done

# Copy starship configuration after mise has installed starship
COPY --chown=$USERNAME:$USERNAME starship.toml /home/$USERNAME/.config/starship.toml

RUN touch ~/.sudo_as_admin_successful

# Standard stage - no Docker-in-Docker
FROM base AS standard
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD []

# Docker-in-Docker stage
FROM base AS dind

USER root

# Copy and install Docker
COPY dind/install-docker.sh /tmp/
RUN bash /tmp/install-docker.sh && rm /tmp/install-docker.sh

# Copy Docker-related files
COPY dind/modprobe /usr/local/bin/ 
RUN chmod +x /usr/local/bin/modprobe

# Copy supervisor configuration
COPY dind/supervisor/ /etc/supervisor/conf.d/

# Create Docker volume
VOLUME /var/lib/docker

# Switch back to the configured user
USER $USERNAME

# Set Docker-specific entrypoint with DIND flag
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD []