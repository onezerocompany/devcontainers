# Docker Images

This document lists all Docker images published from this repository.

## Published Images

### base
- **Registry URL**: `ghcr.io/onezerocompany/base:latest`
- **Source**: `/Users/luca/Projects/devcontainers/images/base/Dockerfile`
- **Platforms**: linux/amd64, linux/arm64

### base:dev
- **Registry URL**: `ghcr.io/onezerocompany/base:dev`
- **Source**: `/Users/luca/Projects/devcontainers/images/base-dev/Dockerfile`
- **Additional Files**: 
  - `/Users/luca/Projects/devcontainers/images/base-dev/vscode-kit`
- **Platforms**: linux/amd64, linux/arm64

### base:dev-docker
- **Registry URL**: `ghcr.io/onezerocompany/base:dev-docker`
- **Source**: `/Users/luca/Projects/devcontainers/images/base-dev-docker/Dockerfile`
- **Additional Files**: 
  - `/Users/luca/Projects/devcontainers/images/base-dev-docker/vscode-kit`
- **Platforms**: linux/amd64, linux/arm64

### base:docker
- **Registry URL**: `ghcr.io/onezerocompany/base:docker`
- **Source**: `/Users/luca/Projects/devcontainers/images/base-docker/Dockerfile`
- **Additional Files**: 
  - `/Users/luca/Projects/devcontainers/images/base-docker/entrypoint.sh`
  - `/Users/luca/Projects/devcontainers/images/base-docker/install-docker.sh`
  - `/Users/luca/Projects/devcontainers/images/base-docker/modprobe`
  - `/Users/luca/Projects/devcontainers/images/base-docker/supervisor/dockerd.conf`
- **Platforms**: linux/amd64, linux/arm64

### runner
- **Registry URL**: `ghcr.io/onezerocompany/runner:latest`
- **Source**: `/Users/luca/Projects/devcontainers/images/runner/Dockerfile`
- **Additional Files**: 
  - `/Users/luca/Projects/devcontainers/images/runner/update-runner.sh`
- **Platforms**: linux/amd64, linux/arm64

### tools
- **Registry URL**: Not published (internal use only)
- **Source**: `/Users/luca/Projects/devcontainers/images/tools/Dockerfile`
- **Additional Files**: 
  - `/Users/luca/Projects/devcontainers/images/tools/gen.sh`