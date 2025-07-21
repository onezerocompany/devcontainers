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

### Sandbox Network Filter (sandbox)

Network traffic filtering for sandboxed environments with domain rule support. Controls and restricts outbound network traffic according to user-defined rules while allowing Docker service communication.

#### Example Usage

```json
"features": {
    "ghcr.io/onezerocompany/features/sandbox:latest": {
        "allowedDomains": "api.github.com,*.openai.com",
        "blockedDomains": "*.facebook.com,*.twitter.com",
        "defaultPolicy": "block",
        "allowDockerNetworks": true,
        "immutableConfig": true
    }
}
```

#### Features

**Network Filtering:**
- **Domain-based blocking**: Support for exact domains, subdomains, and wildcards (*.example.com)
- **DNS-level filtering**: Efficient blocking via hosts file manipulation  
- **iptables integration**: Additional packet filtering for comprehensive control
- **Flexible policies**: Configurable default allow/block behavior for unlisted domains

**Container Compatibility:**
- **Docker network preservation**: Maintains communication with Docker Compose services
- **Local traffic control**: Configurable localhost and private network access
- **Established connections**: Preserves existing container-to-container communications

**Security & Management:**
- **Immutable configuration**: Optional protection against runtime rule modifications
- **Logging support**: Optional logging of blocked connection attempts for debugging
- **LLM sandboxing**: Designed to contain automated tools and prevent unauthorized network access

## Contributing

Please refer to the main repository for contribution guidelines.

## License

See the main repository for license information.