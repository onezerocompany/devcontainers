# OneZero Dev Container Features

A collection of features for development containers.

## Available Features

### Docker-in-Docker (docker-in-docker)

Enables Docker inside a Dev Container by installing the Docker CLI and enabling the Docker daemon.

#### Example Usage

```json
"features": {
    "ghcr.io/onezerocompany/features/docker-in-docker:latest": {
        "version": "latest",
        "moby": false
    }
}
```

### Common Utilities (common-utils)

Comprehensive development utilities with modern CLI tools, shell configurations, and tool bundles including zsh, starship prompt, zoxide, eza, bat, web development tools, networking utilities, container tools, and more.

#### Example Usage

```json
"features": {
    "ghcr.io/onezerocompany/features/common-utils:latest": {
        "defaultShell": "zsh",
        "installStarship": true,
        "installZoxide": true,
        "installEza": true,
        "installBat": true,
        "webDevBundle": true,
        "networkingBundle": true,
        "containersBundle": false,
        "utilitiesBundle": true,
        "configureForRoot": true
    }
}
```

#### Features

**Modern CLI Tools:**
- **Starship**: A minimal, blazing-fast, and infinitely customizable prompt
- **Zoxide**: A smarter cd command that learns your habits
- **Eza**: A modern replacement for ls with colors and git integration
- **Bat**: A cat clone with syntax highlighting and line numbers

**Tool Bundles:**
- **Web Development**: httpie, jq, yq, dasel, database clients, config processing tools
- **Networking**: ssh, nmap, curl, wget, network analysis and debugging tools
- **Containers**: docker, kubernetes, k9s, container analysis and management tools (optional)
- **Utilities**: git tools, system utilities, modern alternatives (fd, ripgrep, tldr)

**Additional Features:**
- **Shell configurations**: Pre-configured bashrc and zshrc with useful aliases
- **Completions**: Automatic shell completions for CLI tools
- **Shim scripts**: Helpful command fallbacks (code, systemctl, devcontainer-info)

## Contributing

Please refer to the main repository for contribution guidelines.

## License

See the main repository for license information.