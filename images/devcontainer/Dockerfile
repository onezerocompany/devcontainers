
ARG BASE_IMAGE_REGISTRY=ghcr.io/onezerocompany
ARG BASE_IMAGE_NAME=base
ARG BASE_IMAGE_TAG=latest

FROM ${BASE_IMAGE_REGISTRY}/${BASE_IMAGE_NAME}:${BASE_IMAGE_TAG} AS main

ARG USERNAME=zero
ARG USER_UID=1000
ARG USER_GID=$USER_UID

USER root

# Copy and run setup scripts
COPY scripts/setup-sandbox.sh /tmp/devcontainer-scripts/
RUN chmod +x /tmp/devcontainer-scripts/*.sh && \
    /tmp/devcontainer-scripts/setup-sandbox.sh

# Copy vscode-kit.sh early since we need to run it
COPY scripts/vscode-kit.sh /usr/local/bin/vscode-kit
RUN chmod +x /usr/local/bin/vscode-kit

# Install vscode-kit
RUN vscode-kit install

# Copy and run motd-gen.sh
COPY scripts/motd-gen.sh /tmp/devcontainer-scripts/
RUN chmod +x /tmp/devcontainer-scripts/motd-gen.sh && \
    /tmp/devcontainer-scripts/motd-gen.sh > /etc/motd && \
    chmod 644 /etc/motd

# Copy configure-shells.sh for later user execution
COPY scripts/configure-shells.sh /tmp/
RUN chmod +x /tmp/configure-shells.sh && \
    chown ${USERNAME}:${USERNAME} /tmp/configure-shells.sh

# Clean up
RUN rm -rf /tmp/devcontainer-scripts

# Copy remaining scripts directly to /usr/local/bin (better caching)
COPY scripts/init-sandbox.sh /usr/local/bin/init-sandbox
RUN chmod +x /usr/local/bin/init-sandbox

COPY scripts/devcontainer-entrypoint.sh /usr/local/bin/devcontainer-entrypoint
RUN chmod +x /usr/local/bin/devcontainer-entrypoint

COPY scripts/hooks/post-create.sh /usr/local/bin/post-create
RUN chmod +x /usr/local/bin/post-create

COPY scripts/hooks/post-attach.sh /usr/local/bin/post-attach
RUN chmod +x /usr/local/bin/post-attach

# Switch to user for user-specific setup
USER $USERNAME

# Copy starship config and set up user environment
COPY --chown=$USERNAME:$USERNAME starship.toml /home/$USERNAME/.config/starship.toml
RUN bash /tmp/configure-shells.sh && rm -f /tmp/configure-shells.sh

# Switch back to root for final steps
USER root

USER $USERNAME

# Test stage
FROM main AS test
USER root
COPY tests/ /tests/
RUN chmod +x /tests/test.sh
USER $USERNAME
WORKDIR /home/$USERNAME
RUN /tests/test.sh

# Clean final stage (inherits from main, not test)
FROM main AS final
ENTRYPOINT ["/usr/local/bin/devcontainer-entrypoint"]
CMD []