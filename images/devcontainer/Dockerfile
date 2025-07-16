ARG BASE_IMAGE_REGISTRY=ghcr.io/onezerocompany
ARG BASE_IMAGE_NAME=base
ARG BASE_IMAGE_TAG=latest

# Select tag based on DIND argument (set BASE_IMAGE_TAG at build time)
FROM ${BASE_IMAGE_REGISTRY}/${BASE_IMAGE_NAME}:${BASE_IMAGE_TAG}

# Re-declare ARG after FROM to use it in the build
ARG DIND=false
ARG USERNAME=zero

USER root

# Copy and run setup-sandbox.sh
COPY scripts/setup-sandbox.sh /tmp/devcontainer-scripts/
RUN chmod +x /tmp/devcontainer-scripts/setup-sandbox.sh && \
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

COPY scripts/entrypoint.sh /usr/local/bin/devcontainer-entrypoint
RUN chmod +x /usr/local/bin/devcontainer-entrypoint

COPY scripts/hooks/post-create.sh /usr/local/bin/post-create
RUN chmod +x /usr/local/bin/post-create

COPY scripts/hooks/post-attach.sh /usr/local/bin/post-attach
RUN chmod +x /usr/local/bin/post-attach

COPY scripts/debug-starship.sh /usr/local/bin/debug-starship
RUN chmod +x /usr/local/bin/debug-starship

# Switch to user for user-specific setup
USER ${USERNAME}

# Copy starship config and set up user environment
COPY --chown=${USERNAME}:${USERNAME} starship.toml /home/${USERNAME}/.config/starship.toml
RUN bash /tmp/configure-shells.sh && rm -f /tmp/configure-shells.sh

# Switch back to root for final steps
USER root

# Use devcontainer entrypoint for all variants
RUN ln -sf /usr/local/bin/devcontainer-entrypoint /usr/local/bin/entrypoint

USER ${USERNAME}

# Use the unified entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint"]
CMD []