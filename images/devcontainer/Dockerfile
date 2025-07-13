# Common stage with all shared dependencies
FROM ghcr.io/onezerocompany/base:latest AS devcontainer-common

USER root

# Common utilities are now installed via mise in the base image
# Clean up apt cache
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Starship is now installed via mise in the base image

# Copy vscode-kit
COPY vscode-kit /usr/local/bin/vscode-kit
RUN chmod +x /usr/local/bin/vscode-kit && \
    vscode-kit install

# Copy utility scripts and configs
COPY starship.toml /etc/skel/.config/starship.toml
COPY scripts/motd-gen.sh /tmp/motd-gen.sh
COPY scripts/post-create.sh /usr/local/bin/devcontainer-post-create

# Set up motd
RUN chmod +x /usr/local/bin/devcontainer-post-create && \
    /tmp/motd-gen.sh > /etc/motd && \
    chmod 644 /etc/motd && \
    rm /tmp/motd-gen.sh

# Standard variant - based on base:latest
FROM ghcr.io/onezerocompany/base:latest AS standard

USER root

# Copy all common installations from devcontainer-common
COPY --from=devcontainer-common /usr/local /usr/local
COPY --from=devcontainer-common /etc/motd /etc/motd
COPY --from=devcontainer-common /etc/skel/.config /etc/skel/.config

# Install sandbox dependencies
RUN apt-get update && apt-get install -y \
    iptables \
    ipset \
    dnsutils \
    curl \
    sudo \
    libcap2-bin && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy and run sandbox setup
COPY scripts/setup-sandbox.sh scripts/entrypoint-wrapper.sh /tmp/
RUN bash /tmp/setup-sandbox.sh && \
    mv /tmp/entrypoint-wrapper.sh /usr/local/bin/devcontainer-entrypoint && \
    chmod 755 /usr/local/bin/devcontainer-entrypoint && \
    chown root:root /usr/local/bin/devcontainer-entrypoint && \
    rm /tmp/setup-sandbox.sh

# Switch to zero user for remaining setup
USER zero

# Set up user environment
RUN mkdir -p /home/zero/.config && \
    cp /etc/skel/.config/starship.toml /home/zero/.config/starship.toml

# Configure shell - append to existing .zshrc instead of overwriting
RUN echo "" >> ~/.zshrc && \
    echo "# Display MOTD only in interactive shells with proper terminal" >> ~/.zshrc && \
    echo "if [[ -o interactive ]] && [[ -t 0 ]] && [[ \"\$TERM\" != \"dumb\" ]]; then" >> ~/.zshrc && \
    echo "    if [ -f /etc/motd ]; then cat /etc/motd; fi" >> ~/.zshrc && \
    echo "fi" >> ~/.zshrc && \
    echo "" >> ~/.zshrc && \
    echo "# Common utilities configuration" >> ~/.zshrc && \
    echo "setopt auto_cd" >> ~/.zshrc && \
    echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> ~/.zshrc && \
    echo "" >> ~/.zshrc && \
    echo "# Activate mise for tool management" >> ~/.zshrc && \
    echo 'eval "$(~/.local/bin/mise activate zsh)"' >> ~/.zshrc && \
    echo "" >> ~/.zshrc && \
    echo "eval \"\$(zoxide init --cmd cd zsh)\"" >> ~/.zshrc && \
    echo "alias cat=\"batcat\"" >> ~/.zshrc && \
    echo "alias ls=\"eza\"" >> ~/.zshrc && \
    echo "alias ll=\"eza -l\"" >> ~/.zshrc && \
    echo "alias la=\"eza -la\"" >> ~/.zshrc && \
    echo "alias tools=\"mise ls\"" >> ~/.zshrc && \
    echo "eval \"\$(starship init zsh)\"" >> ~/.zshrc

# Zoxide is now installed via mise in the base image

# Use the wrapper as entrypoint
ENTRYPOINT ["/usr/local/bin/devcontainer-entrypoint"]
CMD ["zsh", "-l"]

# DIND variant - based on base:dind
FROM ghcr.io/onezerocompany/base:dind AS dind

USER root

# Copy all common installations from devcontainer-common
COPY --from=devcontainer-common /usr/local /usr/local
COPY --from=devcontainer-common /etc/motd /etc/motd
COPY --from=devcontainer-common /etc/skel/.config /etc/skel/.config

# Copy and run docker setup
COPY scripts/setup-docker.sh scripts/docker-init.sh /tmp/
RUN bash /tmp/setup-docker.sh && \
    mv /tmp/docker-init.sh /usr/local/share/docker-init.sh && \
    chmod +x /usr/local/share/docker-init.sh && \
    rm /tmp/setup-docker.sh

# Switch to zero user for remaining setup
USER zero

# Set up user environment
RUN mkdir -p /home/zero/.config && \
    cp /etc/skel/.config/starship.toml /home/zero/.config/starship.toml

# Configure shell - append to existing .zshrc instead of overwriting
RUN echo "" >> ~/.zshrc && \
    echo "# Display MOTD only in interactive shells with proper terminal" >> ~/.zshrc && \
    echo "if [[ -o interactive ]] && [[ -t 0 ]] && [[ \"\$TERM\" != \"dumb\" ]]; then" >> ~/.zshrc && \
    echo "    if [ -f /etc/motd ]; then cat /etc/motd; fi" >> ~/.zshrc && \
    echo "fi" >> ~/.zshrc && \
    echo "" >> ~/.zshrc && \
    echo "# Common utilities configuration" >> ~/.zshrc && \
    echo "setopt auto_cd" >> ~/.zshrc && \
    echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> ~/.zshrc && \
    echo "" >> ~/.zshrc && \
    echo "# Activate mise for tool management" >> ~/.zshrc && \
    echo 'eval "$(~/.local/bin/mise activate zsh)"' >> ~/.zshrc && \
    echo "" >> ~/.zshrc && \
    echo "eval \"\$(zoxide init --cmd cd zsh)\"" >> ~/.zshrc && \
    echo "alias cat=\"batcat\"" >> ~/.zshrc && \
    echo "alias ls=\"eza\"" >> ~/.zshrc && \
    echo "alias ll=\"eza -l\"" >> ~/.zshrc && \
    echo "alias la=\"eza -la\"" >> ~/.zshrc && \
    echo "alias tools=\"mise ls\"" >> ~/.zshrc && \
    echo "eval \"\$(starship init zsh)\"" >> ~/.zshrc

# Zoxide is now installed via mise in the base image

# Use docker-init.sh as the entrypoint to handle socket forwarding
ENTRYPOINT ["/usr/local/share/docker-init.sh"]
CMD ["bash"]