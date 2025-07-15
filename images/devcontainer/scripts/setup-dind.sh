#!/bin/bash -e
# Simplified setup script for Docker-in-Docker
# Most Docker setup is handled by the base image

USERNAME="${USERNAME:-zero}"

# Ensure user is in docker group (base image should have created it)
if grep -qE '^docker:' /etc/group; then
    usermod -aG docker "${USERNAME}"
else
    echo "Warning: docker group not found. Base image may not be DIND variant."
fi

echo "Docker setup complete!"