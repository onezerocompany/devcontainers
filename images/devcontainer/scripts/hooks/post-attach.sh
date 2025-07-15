#!/bin/bash
# VS Code post-attach script
# Called after VS Code attaches to the container

# Wait for initialization to complete
while [ ! -f /tmp/.devcontainer-init-complete ]; do
    sleep 0.5
done

# Additional post-attach actions can be added here