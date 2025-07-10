FROM ghcr.io/onezerocompany/dind

USER root

# Install Node.js 20
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs

# Install devcontainer CLI
RUN npm install -g @devcontainers/cli

COPY vscode-kit /usr/local/bin/vscode-kit
RUN chmod +x /usr/local/bin/vscode-kit

RUN vscode-kit install

USER zero

ENTRYPOINT ["entrypoint.sh"]
CMD ["bash"]