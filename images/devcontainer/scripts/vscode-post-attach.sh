#!/bin/bash
# VS Code post-attach script to handle terminal management
# This script is called after VS Code attaches to the container

# Wait for initialization to complete
while [ ! -f /tmp/.devcontainer-init-complete ]; do
    sleep 0.5
done

# Signal VS Code to open a new terminal
if command -v code &> /dev/null; then
    # Open a new integrated terminal
    code --command workbench.action.terminal.new
fi