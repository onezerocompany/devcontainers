FROM ghcr.io/onezerocompany/base-i

# Install vscode-cli
COPY vscode-cli.sh /tmp/vscode-cli.sh
RUN chmod +x /tmp/vscode-cli.sh && /tmp/vscode-cli.sh
RUN rm /tmp/vscode-cli.sh

# Install 1Password CLI
COPY 1password-cli.sh /tmp/1password-cli.sh
RUN chmod +x /tmp/1password-cli.sh && /tmp/1password-cli.sh
RUN rm /tmp/1password-cli.sh

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Set the default shell to zsh
RUN chsh -s /usr/bin/zsh