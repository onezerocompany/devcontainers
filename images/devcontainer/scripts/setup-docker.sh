#!/bin/bash -e

USERNAME="${USERNAME:-zero}"
ENABLE_NONROOT_DOCKER="${ENABLE_NONROOT_DOCKER:-true}"
SOURCE_SOCKET="${SOURCE_SOCKET:-/var/run/docker-host.sock}"
TARGET_SOCKET="${TARGET_SOCKET:-/var/run/docker.sock}"

# Ensure docker group exists (should already exist in base:dind)
if ! grep -qE '^docker:' /etc/group; then
    echo "(*) Creating missing docker group..."
    groupadd --system docker
fi

# Add user to docker group
usermod -aG docker "${USERNAME}"

# By default, make the source and target sockets the same
if [ "${SOURCE_SOCKET}" != "${TARGET_SOCKET}" ]; then
    touch "${SOURCE_SOCKET}"
    ln -s "${SOURCE_SOCKET}" "${TARGET_SOCKET}"
fi

# Add a stub if not adding non-root user access, user is root
if [ "${ENABLE_NONROOT_DOCKER}" = "false" ] || [ "${USERNAME}" = "root" ]; then
    echo -e '#!/usr/bin/env bash\nexec "$@"' > /usr/local/share/docker-init.sh
    chmod +x /usr/local/share/docker-init.sh
    echo "Docker setup complete (root user)!"
    exit 0
fi

echo "Docker setup complete!"