#!/bin/bash
# VS Code post-attach script
# Called after VS Code attaches to the container

# Wait for initialization to complete with timeout
timeout=30  # 30 seconds timeout
elapsed=0

while [ ! -f /tmp/.devcontainer-init-complete ]; do
    if [ $elapsed -ge $timeout ]; then
        echo "⚠️  Warning: Initialization marker not found after ${timeout}s, proceeding anyway"
        break
    fi
    sleep 0.5
    elapsed=$((elapsed + 1))
done

# Additional post-attach actions can be added here