ARG DIND=false
ARG BASE_IMAGE_REGISTRY=ghcr.io/onezerocompany
ARG BASE_IMAGE_NAME=base

# Use base:dind if DIND=true, otherwise use base:base
FROM ${BASE_IMAGE_REGISTRY}/${BASE_IMAGE_NAME}:base AS base-image-false
FROM ${BASE_IMAGE_REGISTRY}/${BASE_IMAGE_NAME}:dind AS base-image-true
FROM base-image-${DIND} AS devcontainer

# Re-declare ARG after FROM to use it in the build
ARG DIND=false

USER root

# Copy vscode-kit
COPY vscode-kit /usr/local/bin/vscode-kit
RUN chmod +x /usr/local/bin/vscode-kit && \
    vscode-kit install

# Copy utility scripts and configs
COPY starship.toml /etc/skel/.config/starship.toml
COPY scripts/motd-gen.sh /tmp/motd-gen.sh

# Copy configuration scripts
COPY scripts/configure-shells.sh /tmp/configure-shells.sh

# Generate MOTD
RUN /tmp/motd-gen.sh > /etc/motd && \
    chmod 644 /etc/motd && \
    rm /tmp/motd-gen.sh

# Standard variant specific setup
RUN if [ "${DIND}" != "true" ]; then \
        echo "Setting up standard variant..." && \
        # Only install packages not in base
        apt-get update && apt-get install -y \
            ipset \
            dnsutils \
            libcap2-bin && \
        apt-get clean && \
        rm -rf /var/lib/apt/lists/*; \
    fi

# Copy and run sandbox setup for standard variant only
COPY scripts/setup-sandbox.sh /tmp/
RUN if [ "${DIND}" != "true" ] && [ -f /tmp/setup-sandbox.sh ]; then \
        bash /tmp/setup-sandbox.sh && \
        rm /tmp/setup-sandbox.sh; \
    elif [ -f /tmp/setup-sandbox.sh ]; then \
        rm /tmp/setup-sandbox.sh; \
    fi

# For DIND variant, we need to handle entrypoint carefully
# Copy devcontainer entrypoint but preserve DIND functionality
COPY scripts/entrypoint.sh /usr/local/bin/devcontainer-entrypoint
RUN chmod +x /usr/local/bin/devcontainer-entrypoint

# Copy vscode hooks
COPY scripts/hooks/post-create.sh /usr/local/bin/post-create
COPY scripts/hooks/post-attach.sh /usr/local/bin/post-attach
RUN chmod +x /usr/local/bin/post-create /usr/local/bin/post-attach

# Switch to zero user for remaining setup
USER zero

# Set up user environment
RUN mkdir -p /home/zero/.config && \
    if [ -f /etc/skel/.config/starship.toml ]; then \
        cp /etc/skel/.config/starship.toml /home/zero/.config/starship.toml; \
    fi && \
    chmod +x /tmp/configure-shells.sh && \
    /tmp/configure-shells.sh && \
    rm /tmp/configure-shells.sh

# Create wrapper script for DIND that calls both entrypoints
USER root
RUN if [ "${DIND}" = "true" ]; then \
        echo '#!/bin/sh' > /usr/local/bin/entrypoint && \
        echo '# Start supervisor for Docker daemon' >> /usr/local/bin/entrypoint && \
        echo 'sudo /usr/bin/supervisord -c /etc/supervisor/supervisord.conf -n >> /dev/null 2>&1 &' >> /usr/local/bin/entrypoint && \
        echo '' >> /usr/local/bin/entrypoint && \
        echo '# Wait for Docker to start' >> /usr/local/bin/entrypoint && \
        echo 'echo "Starting docker..."' >> /usr/local/bin/entrypoint && \
        echo 'while ! pgrep "dockerd" >/dev/null; do' >> /usr/local/bin/entrypoint && \
        echo '  sleep 1' >> /usr/local/bin/entrypoint && \
        echo 'done' >> /usr/local/bin/entrypoint && \
        echo '' >> /usr/local/bin/entrypoint && \
        echo '# Fix Docker socket permissions' >> /usr/local/bin/entrypoint && \
        echo 'sudo chown zero:zero /var/run/docker.sock 2>/dev/null || true' >> /usr/local/bin/entrypoint && \
        echo '' >> /usr/local/bin/entrypoint && \
        echo '# Run devcontainer initialization' >> /usr/local/bin/entrypoint && \
        echo 'exec /usr/local/bin/devcontainer-entrypoint "$@"' >> /usr/local/bin/entrypoint && \
        chmod +x /usr/local/bin/entrypoint; \
    else \
        # For standard variant, use devcontainer entrypoint directly
        ln -sf /usr/local/bin/devcontainer-entrypoint /usr/local/bin/entrypoint; \
    fi

USER zero

# Use the unified entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint"]
CMD []