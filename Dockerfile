ARG deno="1.11.3"
FROM denoland/deno:alpine-${deno}

# Setup scripts
COPY scripts /scripts
RUN chmod +x /scripts/*

# Add dev user
RUN addgroup --gid 1001 dev \
 && adduser --uid 1001 --disabled-password dev --ingroup dev

# Intall build tools
RUN /scripts/setup.sh

# Setup Deno
ENV DENO_DIR /deno-dir/
ENV DENO_INSTALL_ROOT /usr/local
RUN chown dev:dev /deno-dir/

# # Install Node
ARG node
ARG npm
RUN if [ ${node} ]; then /scripts/install-node.sh ${node}; fi
RUN if [ ${npm} ]; then /scripts/install-npm.sh ${npm}}; fi

# Generate header
ARG dev_env="Typescript"
RUN /scripts/generate-header.sh ${dev_env} ${node}

# Install shell
RUN /scripts/install-zsh.sh

# Cleanup scripts and build tools
RUN /scripts/cleanup.sh

# Install header display
COPY scripts/display-header.sh /display-header.sh
RUN chmod +x /display-header.sh

ENTRYPOINT ["/bin/zsh", "/display-header.sh"]