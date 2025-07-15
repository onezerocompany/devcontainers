ARG BASE_IMAGE_REGISTRY=ghcr.io/onezerocompany
ARG BASE_IMAGE_NAME=base
ARG BASE_IMAGE_TAG=latest

# Select tag based on DIND argument (set BASE_IMAGE_TAG at build time)
FROM ${BASE_IMAGE_REGISTRY}/${BASE_IMAGE_NAME}:${BASE_IMAGE_TAG}

# Re-declare ARG after FROM to use it in the build
ARG DIND=false
ARG USERNAME=zero

USER root

# Copy all scripts at once for better layer caching
COPY scripts/ /tmp/devcontainer-scripts/

# Run all setup scripts and installations in a single layer
RUN set -ex && \
    # Make all scripts executable
    chmod -R +x /tmp/devcontainer-scripts/ && \
    # Run sandbox setup
    /tmp/devcontainer-scripts/setup-sandbox.sh && \
    # Install scripts to proper locations
    mv /tmp/devcontainer-scripts/init-sandbox.sh /usr/local/bin/init-sandbox && \
    mv /tmp/devcontainer-scripts/vscode-kit.sh /usr/local/bin/vscode-kit && \
    mv /tmp/devcontainer-scripts/entrypoint.sh /usr/local/bin/devcontainer-entrypoint && \
    mv /tmp/devcontainer-scripts/hooks/post-create.sh /usr/local/bin/post-create && \
    mv /tmp/devcontainer-scripts/hooks/post-attach.sh /usr/local/bin/post-attach && \
    # Install vscode-kit
    vscode-kit install && \
    # Generate MOTD
    /tmp/devcontainer-scripts/motd-gen.sh > /etc/motd && \
    chmod 644 /etc/motd && \
    # Keep configure-shells.sh for later user execution
    mv /tmp/devcontainer-scripts/configure-shells.sh /tmp/configure-shells.sh && \
    # Clean up remaining scripts
    rm -rf /tmp/devcontainer-scripts

# Switch to user for user-specific setup
USER ${USERNAME}

# Copy starship config and set up user environment
COPY --chown=${USERNAME}:${USERNAME} starship.toml /home/${USERNAME}/.config/starship.toml
RUN bash /tmp/configure-shells.sh && rm -f /tmp/configure-shells.sh

# Switch back to root for final steps
USER root

# Use devcontainer entrypoint for all variants (it handles DIND internally)
RUN ln -sf /usr/local/bin/devcontainer-entrypoint /usr/local/bin/entrypoint

USER ${USERNAME}

# Use the unified entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint"]
CMD []