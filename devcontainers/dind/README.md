# OneZero DIND Devcontainer

A development container optimized for OneZero projects that require Docker support. This container provides full Docker-in-Docker capabilities along with the standard OneZero development tools.

## Features

### Base Image
- **Image**: `ghcr.io/onezerocompany/dind`
- Provides Docker-in-Docker functionality with a full Docker daemon running inside the container

### Included Features

1. **Docker** (v1)
   - Full Docker CLI and tools
   - Docker Buildx support
   - Docker Compose v2
   - Uses Moby (open-source Docker) build
   - Includes VS Code Docker extension

2. **Mise** (v1)
   - Polyglot runtime manager
   - Auto-trust enabled for `.mise.toml` files
   - Supports multiple tool versions

3. **Common Utils** (v2.0.0)
   - Essential shell utilities
   - Git configuration
   - SSH support
   - Starship prompt

## Usage

This devcontainer runs with privileged mode to support Docker-in-Docker functionality. It mounts the host's Docker socket for additional flexibility.

### Post-Create Setup
The container automatically runs `mise install` after creation to install any tools defined in your project's `.mise.toml` file.

### Security Considerations
- Runs in privileged mode for Docker daemon support
- Has access to the host's Docker socket
- Should be used only in trusted environments

## VS Code Integration
- Terminal defaults to Zsh
- Docker extension pre-installed for container management
- Full IntelliSense support for Dockerfiles and docker-compose.yml

## When to Use This Container

Use this devcontainer when you need:
- To build and run Docker containers within your development environment
- Full Docker daemon isolation from the host
- Docker Compose for multi-container applications
- Container-based testing environments

For projects that don't require Docker support, use the standard `onezero` devcontainer instead.