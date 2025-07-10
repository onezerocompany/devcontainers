# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a DevContainers repository that provides:
- Base Docker images for development environments
- DevContainer features (modular components for installing development tools)
- Pre-configured devcontainers (OneZero and OneZero-DIND)

The project publishes to GitHub Container Registry (ghcr.io) and follows the DevContainers specification.

## Common Development Commands

### Testing Features
To test a specific feature:
```bash
cd features/test/[feature-name]
./test.sh
```

Features use the `dev-container-features-test-lib` library for testing. Tests verify tool installation and basic functionality.

### Building Docker Images Locally
Images are located in `/images/` directory:
```bash
# Build base image
docker build -t devcontainer-base ./images/base

# Build specific images (they depend on base)
docker build -t devcontainer-dind ./images/dind
docker build -t devcontainer-base ./images/devcontainer-base
```

### Publishing (CI/CD)
Publishing is automated via GitHub Actions on:
- Push to main branch
- Daily at 3 AM UTC

The workflow publishes:
1. Docker images to `ghcr.io/onezerocompany/[image-name]`
2. DevContainer features to `onezerocompany/devcontainers/features`

## Architecture

### Directory Structure
- `/features/src/` - DevContainer feature definitions
  - Each feature has: `devcontainer-feature.json`, `install.sh`, and `README.md`
- `/features/test/` - Feature tests
- `/images/` - Docker image definitions
- `/devcontainers/` - Pre-configured devcontainer setups

### Image Build Order
1. `base` - Foundation image
2. `dind` - Docker-in-Docker (depends on base)
3. `devcontainer-base` - DevContainer foundation (depends on dind)
4. `runner` - GitHub Actions runner (depends on base)
5. `firebase-toolkit` - Standalone Firebase tools

### Feature System
Features are modular components installed via shell scripts:
- Configuration: `devcontainer-feature.json` defines options and VS Code extensions
- Installation: `install.sh` handles the actual installation
- Default user is typically "zero" (configurable)

### Testing Approach
- Each feature has a `test.sh` that sources `dev-container-features-test-lib`
- Tests run commands through zsh with proper environment loading
- Some features have scenario-based testing via `scenarios.json`

## Important Notes

- Multi-platform builds: Most images support `linux/amd64` and `linux/arm64`
- Features expect a user named "zero" by default (configurable via options)
- VS Code extensions are automatically installed based on feature configurations