# Docker Images

This document lists all Docker images published from this repository.

## Published Images

### base
- **Registry URL**: `ghcr.io/onezerocompany/base:latest`
- **Source**: `/Users/luca/Projects/devcontainers/images/base/Dockerfile`
- **Platforms**: linux/amd64, linux/arm64

### dind
- **Registry URL**: `ghcr.io/onezerocompany/dind:latest`
- **Source**: `/Users/luca/Projects/devcontainers/images/dind/Dockerfile`
- **Additional Files**: 
  - `/Users/luca/Projects/devcontainers/images/dind/entrypoint.sh`
  - `/Users/luca/Projects/devcontainers/images/dind/install-docker.sh`
  - `/Users/luca/Projects/devcontainers/images/dind/modprobe`
  - `/Users/luca/Projects/devcontainers/images/dind/supervisor/dockerd.conf`
- **Platforms**: linux/amd64, linux/arm64

### runner
- **Registry URL**: `ghcr.io/onezerocompany/runner:latest`
- **Source**: `/Users/luca/Projects/devcontainers/images/runner/Dockerfile`
- **Additional Files**: 
  - `/Users/luca/Projects/devcontainers/images/runner/update-runner.sh`
- **Platforms**: linux/amd64, linux/arm64

### devcontainer:base
- **Registry URL**: `ghcr.io/onezerocompany/devcontainer:base`
- **Source**: `/Users/luca/Projects/devcontainers/images/devcontainer:base/Dockerfile`
- **Additional Files**: 
  - `/Users/luca/Projects/devcontainers/images/devcontainer:base/vscode-kit`
  - `/Users/luca/Projects/devcontainers/images/devcontainer:base/sandbox/*`
  - `/Users/luca/Projects/devcontainers/images/devcontainer:base/build-context/*`
- **Platforms**: linux/amd64, linux/arm64

### devcontainer:dind
- **Registry URL**: `ghcr.io/onezerocompany/devcontainer:dind`
- **Source**: `/Users/luca/Projects/devcontainers/images/devcontainer:dind/Dockerfile`
- **Additional Files**: 
  - `/Users/luca/Projects/devcontainers/images/devcontainer:dind/vscode-kit`
  - `/Users/luca/Projects/devcontainers/images/devcontainer:dind/docker-feature/*`
- **Platforms**: linux/amd64, linux/arm64