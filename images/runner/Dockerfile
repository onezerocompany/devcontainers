FROM ghcr.io/onezerocompany/base:latest AS build

ARG TARGETOS
ARG TARGETARCH
ARG RUNNER_CONTAINER_HOOKS_VERSION=0.6.1
ARG DOCKER_VERSION=27.1.1
ARG BUILDX_VERSION=0.16.2

USER root

WORKDIR /actions-runner

# Fetch the latest runner version
COPY update-runner.sh /actions-runner/update-runner.sh
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

FROM ghcr.io/onezerocompany/base:latest AS main

USER root

ENV DEBIAN_FRONTEND=noninteractive
ENV RUNNER_MANUALLY_TRAP_SIG=1
ENV ACTIONS_RUNNER_PRINT_LOG_TO_STDOUT=1
ENV ImageOS=ubuntu22

RUN adduser --disabled-password --gecos "" --uid 1001 runner \
    && groupadd docker --gid 123 \
    && usermod -aG sudo runner \
    && usermod -aG docker runner \
    && echo "runner ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers \
    && echo "Defaults env_keep += \"DEBIAN_FRONTEND\"" >> /etc/sudoers

WORKDIR /home/runner

COPY --chown=runner:docker --from=build /actions-runner .
COPY --from=build /usr/local/lib/docker/cli-plugins/docker-buildx /usr/local/lib/docker/cli-plugins/docker-buildx

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

# Test stage
FROM main AS test
USER root
COPY tests/ /tests/
RUN chmod +x /tests/test.sh
USER runner
WORKDIR /home/runner
RUN /tests/test.sh

# Clean final stage (inherits from main, not test)
FROM main AS final
ENTRYPOINT ["/usr/local/bin/runner-entrypoint"]
