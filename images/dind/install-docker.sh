#!/bin/bash

arch="$(uname -m)"
case "$arch" in
  x86_64) dockerArch='x86_64' ; buildx_arch='linux-amd64' ;;
  armhf) dockerArch='armel' ; buildx_arch='linux-arm-v6' ;;
  armv7) dockerArch='armhf' ; buildx_arch='linux-arm-v7' ;;
  aarch64) dockerArch='aarch64' ; buildx_arch='linux-arm64' ;;
  *) echo >&2 "error: unsupported architecture ($arch)"; exit 1 ;;
esac

function get_latest_docker_version() {
  curl -sSL "https://download.docker.com/linux/static/${DOCKER_CHANNEL}/${dockerArch}/" | \
    grep -o -E 'docker-[0-9]+\.[0-9]+\.[0-9]+' | \
    sort -V | \
    tail -n 1 | \
    cut -d '-' -f 2
}

function get_latest_buildx_version() {
  curl -sSL "https://api.github.com/repos/docker/buildx/releases/latest" | \
    jq -r '.tag_name' | \
    cut -d 'v' -f 2
}

function get_latest_compose_version() {
  curl -sSL "https://api.github.com/repos/docker/compose/releases/latest" | \
    jq -r '.tag_name' | \
    cut -d 'v' -f 2
}

DOCKER_CHANNEL='stable'
DOCKER_VERSION="${DOCKER_VERSION:-$(get_latest_docker_version)}"
BUILDX_VERSION="${BUILDX_VERSION:-$(get_latest_buildx_version)}"
DOCKER_COMPOSE_VERSION="${DOCKER_COMPOSE_VERSION:-$(get_latest_compose_version)}"

echo "Docker version: ${DOCKER_VERSION}"
echo "Buildx version: ${BUILDX_VERSION}"
echo "Docker Compose version: ${DOCKER_COMPOSE_VERSION}"

if ! wget -O docker.tgz "https://download.docker.com/linux/static/${DOCKER_CHANNEL}/${dockerArch}/docker-${DOCKER_VERSION}.tgz"; then
  echo >&2 "error: failed to download 'docker-${DOCKER_VERSION}' from '${DOCKER_CHANNEL}' for '${dockerArch}'"
  exit 1
fi

tar --extract \
  --file docker.tgz \
  --strip-components 1 \
  --directory /usr/local/bin/

rm docker.tgz

if ! wget -O docker-buildx "https://github.com/docker/buildx/releases/download/v${BUILDX_VERSION}/buildx-v${BUILDX_VERSION}.${buildx_arch}"; then
  echo >&2 "error: failed to download 'buildx-${BUILDX_VERSION}.${buildx_arch}'"
  exit 1
fi

mkdir -p /usr/local/lib/docker/cli-plugins
chmod +x docker-buildx
mv docker-buildx /usr/local/lib/docker/cli-plugins/docker-buildx

dockerd --version
docker --version
docker buildx version


curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose \
chmod +x /usr/local/bin/docker-compose && docker-compose version

# Create a symlink to the docker binary in /usr/local/lib/docker/cli-plugins
# for users which uses 'docker compose' instead of 'docker-compose'
ln -s /usr/local/bin/docker-compose /usr/local/lib/docker/cli-plugins/docker-compose

# create docker group
groupadd -g 999 docker

# add user to docker group
usermod -aG docker zero