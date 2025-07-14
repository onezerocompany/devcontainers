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

# Copy and run package installation script
COPY scripts/install-packages.sh /tmp/
RUN chmod +x /tmp/install-packages.sh && \
    /tmp/install-packages.sh && \
    rm /tmp/install-packages.sh

# Create user with configurable name
RUN groupadd --gid $USER_GID $USERNAME && \
    useradd --uid $USER_UID --gid $USER_GID -m $USERNAME && \
    echo "$USERNAME ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
    
# Set up shell configurations for both bash and zsh
COPY scripts/setup-shell-config.sh /tmp/
RUN chmod +x /tmp/setup-shell-config.sh && \
    /tmp/setup-shell-config.sh $USERNAME && \
    rm /tmp/setup-shell-config.sh && \
    chown -R $USERNAME:$USERNAME /home/$USERNAME

WORKDIR /home/$USERNAME
USER $USERNAME

# Install mise as non-root user
RUN curl -fsSL https://mise.run | sh

# Create mise cache directories
RUN mkdir -p ~/.cache/mise && \
    mkdir -p ~/.local/share/mise

# Copy global mise configuration and install tools
COPY --chown=$USERNAME:$USERNAME mise-global.toml /home/$USERNAME/.mise.toml
# Add retry logic for mise install to handle network timeouts
RUN for i in 1 2 3; do \
        echo "Attempt $i: Installing mise tools..." && \
        mise install && break || \
        (echo "Failed attempt $i, retrying in 5 seconds..." && sleep 5); \
    done

RUN touch ~/.sudo_as_admin_successful

# Standard stage - no Docker-in-Docker
FROM base AS standard
CMD ["/bin/zsh"]

# Docker-in-Docker stage
FROM base AS dind

USER root

# Copy and install Docker
COPY scripts/install-docker.sh /tmp/
RUN bash /tmp/install-docker.sh && rm /tmp/install-docker.sh

# Copy Docker-related files
COPY scripts/modprobe scripts/entrypoint.sh /usr/local/bin/ 
RUN chmod +x /usr/local/bin/entrypoint.sh \
	/usr/local/bin/modprobe

# Copy supervisor configuration
COPY supervisor/ /etc/supervisor/conf.d/

# Create Docker volume
VOLUME /var/lib/docker

# Switch back to the configured user
USER $USERNAME

# Set Docker-specific entrypoint
ENTRYPOINT ["entrypoint.sh"]
CMD ["/bin/zsh"]