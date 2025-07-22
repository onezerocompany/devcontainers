FROM docker:24-dind AS main

# Install node 20 on alpine with optimized npm settings
RUN apk add --no-cache nodejs npm jq && \
    npm config set registry https://registry.npmjs.org/ && \
    npm config set fetch-timeout 60000 && \
    npm config set fetch-retries 3 && \
    npm config set progress false && \
    npm install -g @devcontainers/cli --verbose

# Create Docker config directory and file for testing
RUN mkdir -p /root/.docker && \
    echo '{}' > /root/.docker/config.json

# gen.sh
COPY scripts/gen.sh /usr/local/bin/gen.sh
RUN chmod +x /usr/local/bin/gen.sh

# Clean final stage (inherits from main)
FROM main AS final
ENTRYPOINT ["gen.sh"]