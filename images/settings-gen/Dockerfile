FROM docker:dind AS main

# Install node 20 on alpine
RUN apk add --no-cache nodejs npm jq && \
    npm install -g @devcontainers/cli

# Create Docker config directory and file for testing
RUN mkdir -p /root/.docker && \
    echo '{}' > /root/.docker/config.json

# gen.sh
COPY scripts/gen.sh /usr/local/bin/gen.sh
RUN chmod +x /usr/local/bin/gen.sh

# Clean final stage (inherits from main)
FROM main AS final
ENTRYPOINT ["gen.sh"]