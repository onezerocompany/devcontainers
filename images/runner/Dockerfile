FROM ghcr.io/onezerocompany/base:latest AS build

ARG TARGETOS
ARG TARGETARCH
ARG RUNNER_CONTAINER_HOOKS_VERSION=0.7.0
ARG DOCKER_VERSION=27.1.1
ARG BUILDX_VERSION=0.16.2

USER root

WORKDIR /actions-runner

# Fetch the latest runner version
COPY scripts/update-runner.sh /actions-runner/update-runner.sh
RUN chmod +x /actions-runner/update-runner.sh && /actions-runner/update-runner.sh

RUN export RUNNER_ARCH=${TARGETARCH} \
    && if [ "$RUNNER_ARCH" = "amd64" ]; then export RUNNER_ARCH=x64 ; fi \
    && curl -f -L -o runner.tar.gz https://github.com/actions/runner/releases/download/v$(cat /actions-runner/latest-runner-version)/actions-runner-${TARGETOS}-${RUNNER_ARCH}-$(cat /actions-runner/latest-runner-version).tar.gz \
    && tar xzf ./runner.tar.gz \
    && rm runner.tar.gz

RUN curl -f -L -o runner-container-hooks.zip https://github.com/actions/runner-container-hooks/releases/download/v${RUNNER_CONTAINER_HOOKS_VERSION}/actions-runner-hooks-k8s-${RUNNER_CONTAINER_HOOKS_VERSION}.zip \
    && unzip ./runner-container-hooks.zip -d ./k8s \
    && rm runner-container-hooks.zip

RUN export RUNNER_ARCH=${TARGETARCH} \
    && if [ "$RUNNER_ARCH" = "amd64" ]; then export DOCKER_ARCH=x86_64 ; fi \
    && if [ "$RUNNER_ARCH" = "arm64" ]; then export DOCKER_ARCH=aarch64 ; fi \
    && curl -fLo docker.tgz https://download.docker.com/${TARGETOS}/static/stable/${DOCKER_ARCH}/docker-${DOCKER_VERSION}.tgz \
    && tar zxvf docker.tgz \
    && rm -rf docker.tgz \
    && mkdir -p /usr/local/lib/docker/cli-plugins \
    && curl -fLo /usr/local/lib/docker/cli-plugins/docker-buildx \
        "https://github.com/docker/buildx/releases/download/v${BUILDX_VERSION}/buildx-v${BUILDX_VERSION}.linux-${TARGETARCH}" \
    && chmod +x /usr/local/lib/docker/cli-plugins/docker-buildx

# Playwright build stage - separate for optimal caching
FROM ghcr.io/onezerocompany/base:latest AS playwright

ARG NODE_MAJOR=20
ARG PLAYWRIGHT_VERSION=latest

USER root
ENV DEBIAN_FRONTEND=noninteractive

# Install Node.js repository and Node.js in a single layer
# This layer will cache well as NODE_MAJOR rarely changes
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update -y && \
    apt-get install -y --no-install-recommends ca-certificates curl gnupg && \
    mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list && \
    apt-get update -y && \
    apt-get install -y --no-install-recommends nodejs

# Install Playwright globally - separate layer for better caching
RUN npm install -g playwright@${PLAYWRIGHT_VERSION}

# Install Playwright browsers and system dependencies
# This is the heaviest layer but will be cached effectively
RUN playwright install --with-deps chromium firefox webkit msedge && \
    chmod -R 755 /root/.cache/ms-playwright 2>/dev/null || true

FROM ghcr.io/onezerocompany/base:latest AS main

USER root

ENV DEBIAN_FRONTEND=noninteractive
ENV RUNNER_MANUALLY_TRAP_SIG=1
ENV ACTIONS_RUNNER_PRINT_LOG_TO_STDOUT=1
ENV ImageOS=ubuntu22

# Playwright configuration
# Set the browsers path so project installations can find system browsers
ENV PLAYWRIGHT_BROWSERS_PATH=/root/.cache/ms-playwright
# Skip browser downloads during npm install since browsers are pre-installed
# Projects should use system browsers instead of downloading their own
ENV PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1

# Install basic development tools for CI/CD
COPY scripts/basic-tools.sh /tmp/basic-tools.sh
RUN chmod +x /tmp/basic-tools.sh && /tmp/basic-tools.sh && rm /tmp/basic-tools.sh

# Copy Node.js from playwright stage
COPY --from=playwright /usr/bin/node /usr/bin/node
COPY --from=playwright /usr/bin/npm /usr/bin/npm
COPY --from=playwright /usr/bin/npx /usr/bin/npx
COPY --from=playwright /usr/lib/node_modules /usr/lib/node_modules
COPY --from=playwright /usr/include/node /usr/include/node
COPY --from=playwright /usr/share/doc/nodejs /usr/share/doc/nodejs
COPY --from=playwright /usr/share/man/man1/node.1.gz /usr/share/man/man1/node.1.gz

# Copy Playwright installation from playwright stage
COPY --from=playwright /root/.cache/ms-playwright /root/.cache/ms-playwright

# Install Playwright system dependencies only (browsers already copied)
# This reuses the browser binaries from the cached playwright stage
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update -y && \
    npx playwright install-deps && \
    rm -rf /var/lib/apt/lists/*

RUN adduser --disabled-password --gecos "" --uid 1001 runner \
    && groupadd docker --gid 123 \
    && usermod -aG sudo runner \
    && usermod -aG docker runner \
    && echo "runner ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers \
    && echo "Defaults env_keep += \"DEBIAN_FRONTEND\"" >> /etc/sudoers \
    && mkdir -p /home/runner/.local/bin \
    && mkdir -p /home/runner/.cache \
    && mkdir -p /home/runner/.local/share \
    && mkdir -p /home/runner/.config \
    && if [ -d /home/zero/.local/bin ] && [ "$(ls -A /home/zero/.local/bin)" ]; then cp -r /home/zero/.local/bin/* /home/runner/.local/bin/; fi \
    && if [ -d /home/zero/.local/share ] && [ "$(ls -A /home/zero/.local/share)" ]; then cp -r /home/zero/.local/share/* /home/runner/.local/share/; fi \
    && if [ -d /home/zero/.cache ] && [ "$(ls -A /home/zero/.cache)" ]; then cp -r /home/zero/.cache/* /home/runner/.cache/; fi \
    && if [ -f /home/zero/.mise.toml ]; then cp /home/zero/.mise.toml /home/runner/.mise.toml; fi \
    && if [ -f /home/zero/.config/starship.toml ]; then cp /home/zero/.config/starship.toml /home/runner/.config/starship.toml; fi \
    && chown -R runner:runner /home/runner \
    && if [ -f /home/runner/.local/bin/mise ]; then chmod +x /home/runner/.local/bin/mise; fi \
    && chmod -R 777 /home/zero

# Set up mise environment variables for runner user
ENV MISE_CACHE_DIR=/home/runner/.cache/mise
ENV MISE_DATA_DIR=/home/runner/.local/share/mise
ENV MISE_TRUSTED_CONFIG_PATHS="/"
ENV MISE_YES=1

WORKDIR /home/runner

# Switch to runner user and activate mise tools if available
USER runner
RUN if [ -f /home/runner/.local/bin/mise ]; then \
        /bin/bash -c 'eval "$(/home/runner/.local/bin/mise activate bash)" && /home/runner/.local/bin/mise install && /home/runner/.local/bin/mise reshim'; \
    fi

COPY --chown=runner:docker --from=build /actions-runner .
COPY --from=build /usr/local/lib/docker/cli-plugins/docker-buildx /usr/local/lib/docker/cli-plugins/docker-buildx

USER root
RUN install -o root -g root -m 755 docker/* /usr/bin/ && rm -rf docker

# Create an entrypoint that initializes sandbox before running actions
RUN echo '#!/bin/bash' > /usr/local/bin/runner-entrypoint && \
    echo '# Initialize sandbox if available' >> /usr/local/bin/runner-entrypoint && \
    echo 'if [ -x "/usr/local/bin/init-sandbox" ]; then' >> /usr/local/bin/runner-entrypoint && \
    echo '    /usr/local/bin/init-sandbox' >> /usr/local/bin/runner-entrypoint && \
    echo 'fi' >> /usr/local/bin/runner-entrypoint && \
    echo '' >> /usr/local/bin/runner-entrypoint && \
    echo '# Execute the command or run the runner' >> /usr/local/bin/runner-entrypoint && \
    echo 'exec "$@"' >> /usr/local/bin/runner-entrypoint && \
    chmod +x /usr/local/bin/runner-entrypoint

USER runner

# Clean final stage (inherits from main)
FROM main AS final
ENTRYPOINT ["/usr/local/bin/runner-entrypoint"]
