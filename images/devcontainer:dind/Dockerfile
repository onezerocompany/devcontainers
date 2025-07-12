FROM ghcr.io/onezerocompany/base:docker

USER root

# Install Node.js 20
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs

# Install devcontainer CLI
RUN npm install -g @devcontainers/cli

# Copy docker feature files
COPY docker-feature/ /tmp/docker-feature/

# Docker feature configuration
ENV INSTALL="true" \
    VERSION="latest" \
    MOBY="true" \
    MOBYBUILDXVERSION="latest" \
    DOCKERDASHCOMPOSEVERSION="v2" \
    INSTALLDOCKERBUILDX="true" \
    ENABLE_NONROOT_DOCKER="true" \
    SOURCE_SOCKET="/var/run/docker-host.sock" \
    TARGET_SOCKET="/var/run/docker.sock" \
    USERNAME="zero"

# Run the docker feature install script
RUN bash /tmp/docker-feature/install.sh && \
    rm -rf /tmp/docker-feature

COPY vscode-kit /usr/local/bin/vscode-kit
RUN chmod +x /usr/local/bin/vscode-kit

RUN vscode-kit install

USER zero

# Use docker-init.sh as the entrypoint to handle socket forwarding
ENTRYPOINT ["/usr/local/share/docker-init.sh"]
CMD ["bash"]