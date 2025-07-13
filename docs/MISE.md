# mise Integration in DevContainers

## Overview

[mise](https://mise.jdx.dev/) (formerly rtx) is the cornerstone of tool version management in the DevContainers project. It serves as a polyglot runtime manager that unifies the management of development tools across different programming languages and frameworks, replacing traditional version managers like nvm, rbenv, and pyenv.

## Architecture

### 1. Base Image Installation

mise is installed at the foundation level in the base Ubuntu 22.04 image (`images/base/Dockerfile:86-104`):

```dockerfile
# Install mise as non-root user
RUN curl -fsSL https://mise.run | sh

# Set up mise environment variables for caching
ENV MISE_CACHE_DIR=$HOME/.cache/mise
ENV MISE_DATA_DIR=$HOME/.local/share/mise
ENV PATH="$HOME/.local/bin:${PATH}"

# Configure mise to auto-trust config files
ENV MISE_TRUSTED_CONFIG_PATHS="/"
ENV MISE_YES=1

# Add mise activation to shell configs
RUN echo 'eval "$(~/.local/bin/mise activate zsh)"' >> ~/.zshrc && \
    echo 'eval "$(~/.local/bin/mise activate bash)"' >> ~/.bashrc

# Create mise cache directories
RUN mkdir -p ~/.cache/mise && \
    mkdir -p ~/.local/share/mise
```

**Key Configuration Details:**
- Installed as non-root user (default username: "zero")
- Automatic shell activation for both zsh and bash
- Pre-configured environment variables for seamless operation
- Cache and data directories created during build time

### 2. DevContainer Image Enhancement

The devcontainer image (`images/devcontainer/Dockerfile`) reinforces mise integration by adding activation commands to the zsh configuration, ensuring proper tool management in the development environment.

### 3. Automatic Tool Installation

The post-create script (`images/devcontainer/build-context/post-create.sh`) handles automatic tool installation when a container starts:

```bash
# Trust and install mise tools
if command -v mise &> /dev/null; then
    echo "📦 Installing development tools with mise..."
    # Suppress TERM warnings by setting a minimal TERM if not set
    if [ -z "$TERM" ]; then
        export TERM=dumb
    fi
    mise trust --all 2>&1 || true
    mise install --yes 2>&1 || true
    echo "✅ Development tools installed"
else
    echo "⚠️  mise not found, skipping tool installation"
fi
```

This script:
- Automatically trusts all mise configuration files
- Installs tools defined in `.mise.toml`
- Handles terminal environment issues gracefully
- Provides user feedback on installation status

## Configuration

### Project-Level Configuration

Create a `.mise.toml` file in your project root to specify required tools:

```toml
[tools]
node = "20.11.0"
python = "3.11"
go = "1.21"
rust = "stable"
java = "21"
ruby = "3.3"
terraform = "1.7"
kubectl = "1.29"
bun = "latest"
deno = "latest"
```

### Environment Variables

The following environment variables are pre-configured:

| Variable | Value | Purpose |
|----------|-------|---------|
| `MISE_CACHE_DIR` | `$HOME/.cache/mise` | Tool cache location |
| `MISE_DATA_DIR` | `$HOME/.local/share/mise` | mise data storage |
| `MISE_TRUSTED_CONFIG_PATHS` | `/` | Auto-trust all config files |
| `MISE_YES` | `1` | Skip confirmation prompts |

## Usage Patterns

### Common Commands

```bash
# Install all tools defined in .mise.toml
mise install

# Install a specific tool
mise install node@20

# Use a tool temporarily
mise use python@3.11

# List installed tools
mise list

# Update all tools
mise upgrade

# See all available tools
mise plugins list
```

### DevContainer Integration

When using mise with devcontainers, add it as a feature in your `.devcontainer.json`:

```json
{
  "image": "ghcr.io/onezerocompany/base:dev",
  "features": {
    "ghcr.io/onezerocompany/devcontainers/features/mise:1": {
      "version": "latest",
      "enableMiseTrust": true
    }
  },
  "remoteUser": "zero",
  "postCreateCommand": "mise install"
}
```

## Best Practices

### 1. Version Pinning

Always pin tool versions in production environments:

```toml
[tools]
node = "20.11.0"  # Good: Specific version
python = "3.11"   # OK: Minor version pinned
ruby = "latest"   # Avoid in production
```

### 2. Tool Organization

Group related tools and add comments:

```toml
[tools]
# Core languages
node = "20.11.0"
python = "3.11.5"

# Build tools
cmake = "3.28"
make = "4.4"

# Cloud tools
aws = "2.15"
terraform = "1.7.0"
```

### 3. Performance Optimization

mise caches tools in `~/.cache/mise`, which persists across container rebuilds when using volume mounts. This significantly speeds up subsequent container starts.

## Security Considerations

### Auto-Trust Configuration

The default configuration sets `MISE_TRUSTED_CONFIG_PATHS="/"`, which trusts all configuration files. This is convenient for development but should be reviewed for production use:

```bash
# More restrictive trust configuration
export MISE_TRUSTED_CONFIG_PATHS="/workspace,/home/zero/projects"
```

### Confirmation Bypassing

`MISE_YES=1` bypasses all confirmation prompts. Consider removing this in sensitive environments:

```bash
# Require confirmations
unset MISE_YES
```

## Troubleshooting

### Common Issues

1. **Tools not installing automatically**
   - Ensure `.mise.toml` exists in the project root
   - Check post-create command execution in VS Code output

2. **Permission errors**
   - mise should be installed as the non-root user
   - Check directory ownership in `~/.cache/mise`

3. **Shell activation not working**
   - Verify shell configuration files contain activation commands
   - Restart the shell or source the configuration file

### Debug Commands

```bash
# Check mise installation
which mise

# Verify environment variables
env | grep MISE

# Check trusted paths
mise trust list

# View mise configuration
mise config

# Check installed plugins
mise plugins list --installed
```

## Migration Guide

### From Traditional Version Managers

Replace traditional version managers with mise:

```bash
# Instead of nvm
# nvm install 20.11.0
mise install node@20.11.0

# Instead of rbenv
# rbenv install 3.3.0
mise install ruby@3.3.0

# Instead of pyenv
# pyenv install 3.11.5
mise install python@3.11.5
```

### Existing Projects

1. Create `.mise.toml` with current tool versions
2. Remove old version manager configurations
3. Update CI/CD pipelines to use mise
4. Document the change for team members

## Advanced Features

### Plugin Development

mise supports custom plugins for tools not in the default registry:

```bash
# Add custom plugin
mise plugins add mytool https://github.com/user/mise-mytool.git

# Install the tool
mise install mytool@1.0.0
```

### Environment Variables

mise can manage environment variables per tool:

```toml
[tools]
node = "20.11.0"

[env]
NODE_ENV = "development"
DATABASE_URL = "postgresql://localhost/myapp"
```

## Contributing

When contributing to the DevContainers project:

1. Test mise integration in your changes
2. Update `.mise.toml` if adding new tool requirements
3. Document any mise-specific configurations
4. Ensure compatibility with the auto-trust settings

## References

- [mise Documentation](https://mise.jdx.dev/)
- [mise GitHub Repository](https://github.com/jdx/mise)
- [DevContainers Specification](https://containers.dev/)
- [Project README](../README.md)