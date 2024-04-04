FROM docker:dind

# Install node 20 on alpine
RUN apk add --no-cache nodejs npm jq && \
    npm install -g @devcontainers/cli

# gen.sh
COPY gen.sh /usr/local/bin/gen.sh
RUN chmod +x /usr/local/bin/gen.sh

ENTRYPOINT ["gen.sh"]