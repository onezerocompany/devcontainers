FROM docker:dind AS main

# Install node 20 on alpine
RUN apk add --no-cache nodejs npm jq && \
    npm install -g @devcontainers/cli

# gen.sh
COPY gen.sh /usr/local/bin/gen.sh
RUN chmod +x /usr/local/bin/gen.sh

# Test stage
FROM main AS test
COPY tests/ /tests/
RUN chmod +x /tests/test.sh && /tests/test.sh

# Clean final stage (inherits from main, not test)
FROM main AS final
ENTRYPOINT ["gen.sh"]