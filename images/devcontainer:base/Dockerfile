FROM ghcr.io/onezerocompany/base

USER root

# Install Node.js 20
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs

# Install devcontainer CLI
RUN npm install -g @devcontainers/cli

COPY vscode-kit /usr/local/bin/vscode-kit
RUN chmod +x /usr/local/bin/vscode-kit

RUN vscode-kit install

# Install common utilities
RUN apt-get update && apt-get install -y \
    fzf \
    bat && \
    # Install eza
    mkdir -p /etc/apt/keyrings && \
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | gpg --dearmor -o /etc/apt/keyrings/gierens.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | tee /etc/apt/sources.list.d/gierens.list && \
    chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list && \
    apt-get update && \
    apt-get install -y eza && \
    # Clean up
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install starship prompt
RUN curl -sS https://starship.rs/install.sh | sh -s -- --yes

# Copy utility scripts and configs
COPY build-context/tools.sh /usr/local/bin/tools
COPY build-context/starship.toml /etc/skel/.config/starship.toml
COPY build-context/motd_gen.sh /tmp/motd_gen.sh

# Set up tools command and motd
RUN chmod +x /usr/local/bin/tools && \
    /tmp/motd_gen.sh > /etc/motd && \
    chmod 644 /etc/motd && \
    rm /tmp/motd_gen.sh

# Switch to zero user for remaining setup
USER zero

# Set up user environment
RUN mkdir -p /home/zero/.config && \
    cp /etc/skel/.config/starship.toml /home/zero/.config/starship.toml

# Configure shell
RUN echo "# Display MOTD" >> ~/.zshrc && \
    echo "if [ -f /etc/motd ]; then cat /etc/motd; fi" >> ~/.zshrc && \
    echo "" >> ~/.zshrc && \
    echo "# Common utilities configuration" >> ~/.zshrc && \
    echo "setopt auto_cd" >> ~/.zshrc && \
    echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> ~/.zshrc && \
    echo "eval \"\$(zoxide init --cmd cd zsh)\"" >> ~/.zshrc && \
    echo "alias cat=\"batcat\"" >> ~/.zshrc && \
    echo "alias ls=\"eza\"" >> ~/.zshrc && \
    echo "alias ll=\"eza -l\"" >> ~/.zshrc && \
    echo "alias la=\"eza -la\"" >> ~/.zshrc && \
    echo "eval \"\$(starship init zsh)\"" >> ~/.zshrc

# Install zoxide as user
RUN curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash

USER root

# Copy sandbox feature files
COPY sandbox/ /tmp/sandbox/

# Install sandbox dependencies (always installed, but activation is runtime-controlled)
RUN apt-get update && apt-get install -y \
    iptables \
    ipset \
    dnsutils \
    curl \
    sudo \
    libcap2-bin && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Run sandbox installation with environment variables
ENV ENABLEFIREWALL="true" \
    USER="zero"

RUN bash /tmp/sandbox/install.sh && \
    rm -rf /tmp/sandbox/install.sh /tmp/sandbox/devcontainer-feature.json /tmp/sandbox/README.md

# Copy and set up the secure entrypoint wrapper
COPY sandbox/entrypoint-wrapper.sh /usr/local/bin/devcontainer-entrypoint
RUN chmod 755 /usr/local/bin/devcontainer-entrypoint && \
    # Make the wrapper immutable (only root can modify)
    chown root:root /usr/local/bin/devcontainer-entrypoint

# Ensure firewall script is also protected
RUN chown root:root /usr/local/share/sandbox/init-firewall.sh && \
    chmod 755 /usr/local/share/sandbox/init-firewall.sh && \
    # Add sudo permissions for the wrapper to create state directory
    echo "zero ALL=(ALL) NOPASSWD: /bin/mkdir -p /var/lib/devcontainer-sandbox" >> /etc/sudoers.d/sandbox && \
    echo "zero ALL=(ALL) NOPASSWD: /bin/chmod 755 /var/lib/devcontainer-sandbox" >> /etc/sudoers.d/sandbox && \
    echo "zero ALL=(ALL) NOPASSWD: /usr/bin/tee /var/lib/devcontainer-sandbox/*" >> /etc/sudoers.d/sandbox && \
    echo "zero ALL=(ALL) NOPASSWD: /bin/chmod 444 /var/lib/devcontainer-sandbox/*" >> /etc/sudoers.d/sandbox && \
    echo "zero ALL=(ALL) NOPASSWD: /sbin/iptables -L OUTPUT -n" >> /etc/sudoers.d/sandbox

# Switch back to zero for runtime
USER zero

# Use the wrapper as entrypoint
ENTRYPOINT ["/usr/local/bin/devcontainer-entrypoint"]
CMD ["zsh", "-l"]