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

### Modern Shell Tools (modern-shell)

Installs and configures modern CLI tools including zsh, starship prompt, zoxide, eza, and bat.

#### Example Usage

```json
"features": {
    "ghcr.io/onezerocompany/features/modern-shell:latest": {
        "defaultShell": "zsh",
        "installStarship": true,
        "installZoxide": true,
        "installEza": true,
        "installBat": true,
        "configureForRoot": true
    }
}
```

#### Features

- **Starship**: A minimal, blazing-fast, and infinitely customizable prompt
- **Zoxide**: A smarter cd command that learns your habits
- **Eza**: A modern replacement for ls with colors and git integration
- **Bat**: A cat clone with syntax highlighting and line numbers
- **Shell configurations**: Pre-configured bashrc and zshrc with useful aliases

## Contributing

Please refer to the main repository for contribution guidelines.

## License

See the main repository for license information.