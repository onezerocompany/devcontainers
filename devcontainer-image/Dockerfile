FROM ghcr.io/onezerocompany/base

USER root

# Install common utils
COPY common-utils.sh /tmp/common-utils.sh
RUN chmod +x /tmp/common-utils.sh && /tmp/common-utils.sh

# Install vscode-cli
COPY vscode-cli.sh /tmp/vscode-cli.sh
RUN chmod +x /tmp/vscode-cli.sh && /tmp/vscode-cli.sh

# Install 1Password CLI
COPY 1password-cli.sh /tmp/1password-cli.sh
RUN chmod +x /tmp/1password-cli.sh && /tmp/1password-cli.sh

COPY motd /etc/motd
RUN chmod 644 /etc/motd
RUN echo "cat /etc/motd" >> /home/coder/.zshrc

RUN rm -rf /tmp/*

USER coder