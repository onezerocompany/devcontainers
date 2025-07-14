# Common stage with all shared dependencies
FROM ghcr.io/onezerocompany/devcontainer:base AS devcontainer-common

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
COPY scripts/entrypoint.sh /usr/local/bin/entrypoint
COPY scripts/vscode-post-attach.sh /usr/local/bin/vscode-post-attach

# Set up motd and entrypoint
RUN chmod +x /usr/local/bin/devcontainer-post-create /usr/local/bin/entrypoint /usr/local/bin/vscode-post-attach && \
    /tmp/motd-gen.sh > /etc/motd && \
    chmod 644 /etc/motd && \
    rm /tmp/motd-gen.sh

# Standard variant - based on base:latest
FROM ghcr.io/onezerocompany/devcontainer:base AS standard

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
COPY scripts/setup-sandbox.sh /tmp/
RUN bash /tmp/setup-sandbox.sh && \
    rm /tmp/setup-sandbox.sh

# Switch to zero user for remaining setup
USER zero

# Set up user environment
RUN mkdir -p /home/zero/.config && \
    cp /etc/skel/.config/starship.toml /home/zero/.config/starship.toml

# Configure shell - append devcontainer-specific config to existing .zshrc
RUN echo '' >> ~/.zshrc && \
    echo '' >> ~/.zshrc && \
    echo '# DevContainer specific configuration' >> ~/.zshrc && \
    echo '# Display MOTD only in interactive shells with proper terminal' >> ~/.zshrc && \
    echo 'if [[ -o interactive ]] && [[ -t 0 ]] && [[ "$TERM" != "dumb" ]]; then' >> ~/.zshrc && \
    echo '    if [ -f /etc/motd ]; then cat /etc/motd; fi' >> ~/.zshrc && \
    echo 'fi' >> ~/.zshrc && \
    echo '' >> ~/.zshrc && \
    echo '# Shell options' >> ~/.zshrc && \
    echo 'setopt auto_cd' >> ~/.zshrc && \
    echo '' >> ~/.zshrc && \
    echo '# Tool initialization (these require mise-installed tools to be in PATH)' >> ~/.zshrc && \
    echo 'if command -v zoxide >/dev/null 2>&1; then' >> ~/.zshrc && \
    echo '    eval "$(zoxide init --cmd cd zsh)"' >> ~/.zshrc && \
    echo 'fi' >> ~/.zshrc && \
    echo '' >> ~/.zshrc && \
    echo '# Aliases for modern CLI tools' >> ~/.zshrc && \
    echo 'if command -v batcat >/dev/null 2>&1; then' >> ~/.zshrc && \
    echo '    alias cat="batcat"' >> ~/.zshrc && \
    echo 'fi' >> ~/.zshrc && \
    echo '' >> ~/.zshrc && \
    echo 'if command -v eza >/dev/null 2>&1; then' >> ~/.zshrc && \
    echo '    alias ls="eza"' >> ~/.zshrc && \
    echo '    alias ll="eza -l"' >> ~/.zshrc && \
    echo '    alias la="eza -la"' >> ~/.zshrc && \
    echo 'fi' >> ~/.zshrc && \
    echo '' >> ~/.zshrc && \
    echo '# Mise tools alias' >> ~/.zshrc && \
    echo 'alias tools="mise ls --current"' >> ~/.zshrc && \
    echo '' >> ~/.zshrc && \
    echo '# Initialize starship prompt (must be last)' >> ~/.zshrc && \
    echo 'if command -v starship >/dev/null 2>&1; then' >> ~/.zshrc && \
    echo '    eval "$(starship init zsh)"' >> ~/.zshrc && \
    echo 'fi' >> ~/.zshrc

# Zoxide is now installed via mise in the base image

# Use the unified entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint"]
CMD []

# DIND variant - based on base:dind
FROM ghcr.io/onezerocompany/devcontainer:dind AS dind

USER root

# Copy all common installations from devcontainer-common
COPY --from=devcontainer-common /usr/local /usr/local
COPY --from=devcontainer-common /etc/motd /etc/motd
COPY --from=devcontainer-common /etc/skel/.config /etc/skel/.config

# Copy and run docker setup
COPY scripts/setup-docker.sh /tmp/
RUN bash /tmp/setup-docker.sh && \
    rm /tmp/setup-docker.sh

# Switch to zero user for remaining setup
USER zero

# Set up user environment
RUN mkdir -p /home/zero/.config && \
    cp /etc/skel/.config/starship.toml /home/zero/.config/starship.toml

# Configure shell - append devcontainer-specific config to existing .zshrc
RUN echo '' >> ~/.zshrc && \
    echo '' >> ~/.zshrc && \
    echo '# DevContainer specific configuration' >> ~/.zshrc && \
    echo '# Display MOTD only in interactive shells with proper terminal' >> ~/.zshrc && \
    echo 'if [[ -o interactive ]] && [[ -t 0 ]] && [[ "$TERM" != "dumb" ]]; then' >> ~/.zshrc && \
    echo '    if [ -f /etc/motd ]; then cat /etc/motd; fi' >> ~/.zshrc && \
    echo 'fi' >> ~/.zshrc && \
    echo '' >> ~/.zshrc && \
    echo '# Shell options' >> ~/.zshrc && \
    echo 'setopt auto_cd' >> ~/.zshrc && \
    echo '' >> ~/.zshrc && \
    echo '# Tool initialization (these require mise-installed tools to be in PATH)' >> ~/.zshrc && \
    echo 'if command -v zoxide >/dev/null 2>&1; then' >> ~/.zshrc && \
    echo '    eval "$(zoxide init --cmd cd zsh)"' >> ~/.zshrc && \
    echo 'fi' >> ~/.zshrc && \
    echo '' >> ~/.zshrc && \
    echo '# Aliases for modern CLI tools' >> ~/.zshrc && \
    echo 'if command -v batcat >/dev/null 2>&1; then' >> ~/.zshrc && \
    echo '    alias cat="batcat"' >> ~/.zshrc && \
    echo 'fi' >> ~/.zshrc && \
    echo '' >> ~/.zshrc && \
    echo 'if command -v eza >/dev/null 2>&1; then' >> ~/.zshrc && \
    echo '    alias ls="eza"' >> ~/.zshrc && \
    echo '    alias ll="eza -l"' >> ~/.zshrc && \
    echo '    alias la="eza -la"' >> ~/.zshrc && \
    echo 'fi' >> ~/.zshrc && \
    echo '' >> ~/.zshrc && \
    echo '# Mise tools alias' >> ~/.zshrc && \
    echo 'alias tools="mise ls --current"' >> ~/.zshrc && \
    echo '' >> ~/.zshrc && \
    echo '# Initialize starship prompt (must be last)' >> ~/.zshrc && \
    echo 'if command -v starship >/dev/null 2>&1; then' >> ~/.zshrc && \
    echo '    eval "$(starship init zsh)"' >> ~/.zshrc && \
    echo 'fi' >> ~/.zshrc

# Use the unified entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint"]
CMD []