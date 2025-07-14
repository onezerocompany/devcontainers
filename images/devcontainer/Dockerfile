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
COPY scripts/entrypoint.sh /usr/local/bin/entrypoint
COPY scripts/vscode-post-attach.sh /usr/local/bin/vscode-post-attach

# Set up motd and entrypoint
RUN chmod +x /usr/local/bin/devcontainer-post-create /usr/local/bin/entrypoint /usr/local/bin/vscode-post-attach && \
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
COPY scripts/setup-sandbox.sh /tmp/
RUN bash /tmp/setup-sandbox.sh && \
    rm /tmp/setup-sandbox.sh

# Switch to zero user for remaining setup
USER zero

# Set up user environment
RUN mkdir -p /home/zero/.config && \
    cp /etc/skel/.config/starship.toml /home/zero/.config/starship.toml

# Configure shell - append devcontainer-specific config to existing .zshrc
RUN cat >> ~/.zshrc << 'EOF'

# DevContainer specific configuration
# Display MOTD only in interactive shells with proper terminal
if [[ -o interactive ]] && [[ -t 0 ]] && [[ "$TERM" != "dumb" ]]; then
    if [ -f /etc/motd ]; then cat /etc/motd; fi
fi

# Shell options
setopt auto_cd

# Tool initialization (these require mise-installed tools to be in PATH)
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init --cmd cd zsh)"
fi

# Aliases for modern CLI tools
if command -v batcat >/dev/null 2>&1; then
    alias cat="batcat"
fi

if command -v eza >/dev/null 2>&1; then
    alias ls="eza"
    alias ll="eza -l"
    alias la="eza -la"
fi

# Mise tools alias
alias tools="mise ls --current"

# Initialize starship prompt (must be last)
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi
EOF

# Zoxide is now installed via mise in the base image

# Use the unified entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint"]
CMD []

# DIND variant - based on base:dind
FROM ghcr.io/onezerocompany/base:dind AS dind

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
RUN cat >> ~/.zshrc << 'EOF'

# DevContainer specific configuration
# Display MOTD only in interactive shells with proper terminal
if [[ -o interactive ]] && [[ -t 0 ]] && [[ "$TERM" != "dumb" ]]; then
    if [ -f /etc/motd ]; then cat /etc/motd; fi
fi

# Shell options
setopt auto_cd

# Tool initialization (these require mise-installed tools to be in PATH)
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init --cmd cd zsh)"
fi

# Aliases for modern CLI tools
if command -v batcat >/dev/null 2>&1; then
    alias cat="batcat"
fi

if command -v eza >/dev/null 2>&1; then
    alias ls="eza"
    alias ll="eza -l"
    alias la="eza -la"
fi

# Mise tools alias
alias tools="mise ls --current"

# Initialize starship prompt (must be last)
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi
EOF

# Use the unified entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint"]
CMD []