# OneZero DevContainers

A unified development container setup that uses [mise](https://mise.jdx.dev/) for managing programming languages and development tools.

## Quick Start

Use the OneZero devcontainer in your project:

```json
{
  "name": "OneZero Devcontainer",
  "image": "ghcr.io/onezerocompany/devcontainer-base",
  "features": {
    "ghcr.io/onezerocompany/devcontainers/features/mise:1": {
      "version": "latest",
      "enableMiseTrust": true
    },
    "ghcr.io/onezerocompany/devcontainers/features/common-utils:1": {}
  },
  "remoteUser": "zero",
  "postCreateCommand": "mise install"
}
```

## Available Features

### Core Features

- **mise** - Polyglot runtime manager for managing all development tools
- **common-utils** - Essential shell utilities (zoxide, eza, bat, starship, etc.)

### Special Purpose Features

- **docker** - Docker-in-Docker support for container development
- **sandbox** - Claude Code CLI with sandboxed environment and persistent state

## Tool Management with mise

Instead of installing fixed versions of tools through devcontainer features, we now use mise to manage tool versions. This provides:

- Easy version switching without rebuilding containers
- Project-specific tool versions via `.mise.toml`
- Consistent tool management across all projects

### Example .mise.toml

```toml
[tools]
# Programming languages
node = "lts"
python = "3.12"
go = "latest"
rust = "stable"

# Development tools
github-cli = "latest"
kubectl = "latest"
helm = "latest"
gcloud = "latest"
firebase = "latest"
trivy = "latest"
1password-cli = "latest"
# Add flutter if needed: flutter = "latest"

[settings]
experimental = true
trusted_config_paths = ["/workspaces"]
```


## Available Docker Images

- `ghcr.io/onezerocompany/base` - Base Ubuntu image
- `ghcr.io/onezerocompany/dind` - Docker-in-Docker image
- `ghcr.io/onezerocompany/devcontainer-base` - DevContainer foundation image
- `ghcr.io/onezerocompany/runner` - GitHub Actions runner
- `ghcr.io/onezerocompany/firebase-toolkit` - Firebase tools

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on contributing to this project.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.