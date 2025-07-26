# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a devcontainers repository that provides reusable features, images, and templates for development containers following the official devcontainer specification. The repository is structured to automatically publish components to GitHub Container Registry (ghcr.io/onezerocompany/).

## Architecture

The repository consists of three main component types:

1. **Features** (`/features/src/`): Installable components that add functionality to containers
   - `modern-shell`: Modern shell environment with Zsh, Starship prompt, and development utilities (fd, ripgrep, bat, eza, zoxide, neovim)
   - `mise-en-place`: Fast polyglot runtime manager (formerly rtx) with persistent volumes for tools and configurations
   - `sandbox`: Network traffic filtering using iptables for sandboxed environments with Claude integration
   - `onezero-motd`: Customizable ASCII Message of the Day with system information

2. **Images** (`/images/`): Base Docker images
   - `base`: Main development container with essential dev tools
   - `runner`: GitHub Actions runner (extends base)
   - `settings-gen`: Settings generation utility

3. **Templates** (`/templates/`): Pre-configured devcontainer setups
   - `base`: Basic development container

## Common Commands

### Testing Features
```bash
# Run tests for a specific feature
cd features/test/modern-shell
./test.sh

# Tests use the dev-container-features-test-lib
# Test scenarios are defined in scenarios.json
```

### Version Management
When modifying any feature or template, always update the version in:
- Features: `features/src/<feature-name>/devcontainer-feature.json`
- Templates: `templates/<template-name>/devcontainer-template.json`

Use semantic versioning (e.g., 1.0.0 → 1.0.1 for patches, 1.1.0 for features, 2.0.0 for breaking changes).

### Publishing
Publishing is automated via GitHub Actions on push to main. The workflow:
1. Publishes features to `ghcr.io/onezerocompany/features`
2. Publishes templates to `ghcr.io/onezerocompany/templates`
3. Builds and pushes Docker images with multi-platform support (amd64/arm64)
4. Pre-builds devcontainer images for templates

### Adding Components

**New Feature:**
1. Create directory: `features/src/<feature-name>/`
2. Add `devcontainer-feature.json` with metadata
3. Add `install.sh` installation script
4. Create tests in `features/test/<feature-name>/`
5. Update version when making changes

**New Template:**
1. Create directory: `templates/<template-name>/`
2. Add `.devcontainer/devcontainer.json`
3. Add `devcontainer-template.json` metadata
4. Reference features from `ghcr.io/onezerocompany/features`

**New Image:**
1. Create directory: `images/<image-name>/`
2. Add Dockerfile and supporting scripts
3. Update `.github/workflows/publish.yml` to include new image job

## Key Implementation Details

### Feature Installation Scripts
- Must be executable bash scripts
- Run as root during container build
- Should handle multiple OS distributions
- Use environment variables for configuration options

### Multi-Platform Support
All images and features support both `linux/amd64` and `linux/arm64`. The CI uses Docker buildx with QEMU emulation for cross-platform builds.

## Repository-Specific Conventions

1. All features are published under `ghcr.io/onezerocompany/features`
2. Use `zero` as the default non-root user (not `vscode` or `node`)
3. Modern shell tools are configured for both user and root
4. Features should be composable and work independently
5. Always bump versions when making any changes to features or templates

## Workflow and Best Practices

- **CI/CD Verification:**
  - Don't assume you've fixed something until you've confirmed the check-suites have completed successfully on GitHub

## Release Management

- Whenever we bump a feature we should also bump the templates that use them