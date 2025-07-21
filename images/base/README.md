# DevContainer Base Image

A comprehensive Debian 12 (Bookworm) based development container image built on buildpack-deps, designed for modern development workflows with pre-installed tools and utilities.

## Overview

This base image provides a comprehensive development environment with all essential tools.

## Bill of Materials (BOM)

### Base System
- **OS**: Debian 12 (Bookworm) via buildpack-deps
- **Architecture**: Multi-arch support (AMD64, ARM64)
- **User**: Configurable non-root user (default: `zero`)
- **Base Image**: buildpack-deps:bookworm (includes 52+ development packages)

### Package Management
- **apt-fast**: Accelerated package downloads with aria2

### Core Development Tools

#### Version Management & Tool Installation
- **mise**: Modern version manager that installs and manages development tools
  
##### Tools Installed via mise (.mise.toml)
- **Node.js LTS**: JavaScript runtime (latest LTS version)
- **Starship**: Cross-shell prompt (latest version)
- **zoxide**: Smarter cd command (latest version)
- **fzf**: Command-line fuzzy finder (latest version)
- **bat 0.24.0**: Cat clone with syntax highlighting
- **eza**: Modern replacement for ls (latest version)

These tools are installed globally for the user during the image build process using mise's configuration file.

#### Build Tools (Beyond buildpack-deps)
- cmake
- Additional tools via buildpack-deps: gcc, g++, make, autoconf, automake, libtool, patch, file, dpkg-dev

#### Programming Languages & Runtimes
- Python 3 (minimal)
- Node.js LTS (via mise)
- GCC/G++ (via buildpack-deps)

#### Version Control
- Git (via buildpack-deps)
- Mercurial, Subversion (via buildpack-deps)
- GPG/GnuPG (via buildpack-deps)

#### Container Tools
- skopeo (container image operations)
- iptables (legacy mode)

#### Shell & Terminal
- bash (default system shell)
- zsh (user shell)
- Starship prompt
- zoxide (smart cd)
- fzf (fuzzy finder)

#### File Operations
- curl, wget (via buildpack-deps)
- tar, xz-utils (via buildpack-deps)
- zip (we install)
- unzip (via buildpack-deps)
- jq (JSON processor)
- bat (syntax-highlighted cat)
- eza (modern ls)

#### Text Editors
- nano
- vim

#### Security & Authentication
- sudo (passwordless for user)
- ca-certificates (via buildpack-deps)
- gnome-keyring
- libssl-dev (via buildpack-deps)
- libgssapi-krb5-2

#### Development Libraries (Beyond buildpack-deps)
- libz3-dev
- libicu-dev
- libedit2
- libsqlite3-0 (runtime, buildpack-deps has libsqlite3-dev)
- libglu1-mesa
- pkg-config
- binutils
- Additional 40+ dev libraries via buildpack-deps (see BUILDPACK-DEPS-BOM.md)

#### System Utilities
- lsb-release
- tzdata
- iptables (legacy mode)

### Environment Configuration

#### Environment Variables
- `LANG=C.UTF-8`
- `LC_ALL=C.UTF-8`
- `DEBIAN_FRONTEND=noninteractive`
- `DOTNET_RUNNING_IN_CONTAINER=true`
- `ASPNETCORE_URLS=http://+:80`
- `MISE_CACHE_DIR=$HOME/.cache/mise`
- `MISE_DATA_DIR=$HOME/.local/share/mise`
- `MISE_TRUSTED_CONFIG_PATHS=/`
- `MISE_YES=1`
- `PATH=$HOME/.local/bin:$PATH`

#### Shell Configuration
- Customized bash and zsh configurations
- Starship prompt integration
- Common utilities and aliases
- Git-aware prompt

### Directory Structure
```
/home/$USERNAME/
├── .cache/mise/          # mise cache
├── .local/
│   ├── bin/             # User binaries
│   └── share/mise/      # mise data
├── .mise.toml           # mise configuration
└── .sudo_as_admin_successful
```

### Scripts
- **entrypoint.sh**: Container entry point handling shell initialization
- **configure-shells.sh**: Shell configuration setup for bash and zsh
- **install-packages.sh**: Package installation script

### Volumes
- `/home/$USERNAME/.cache/mise` - mise download cache
- `/home/$USERNAME/.local/share/mise` - mise installed tools and data

## Usage

### Building the Image

```bash
docker build -t devcontainer-base:latest .
```

### Build Arguments
- `USERNAME`: User name (default: zero)
- `USER_UID`: User ID (default: 1000)
- `USER_GID`: Group ID (default: same as UID)

### Running Containers

```bash
# Basic usage
docker run -it devcontainer-base:latest

# With mise cache volumes for persistence
docker run -it \
  -v mise-cache:/home/zero/.cache/mise \
  -v mise-data:/home/zero/.local/share/mise \
  devcontainer-base:latest
```

## Features

### Multi-stage Build
- Optimized layer caching
- Built on buildpack-deps for comprehensive dev tools
- Minimal additional layers

### Security
- Non-root user by default
- Passwordless sudo for development
- GPG and keyring support

### Developer Experience  
- Modern CLI tools installed via mise (starship, zoxide, fzf, bat, eza)
- Pre-configured shells with useful aliases
- Git integration
- Centralized tool version management through .mise.toml
- Automatic tool installation during image build
- Comprehensive development libraries via buildpack-deps

## How mise Works in This Image

The image uses mise as the primary tool manager:
1. mise is installed during the build process as the non-root user
2. The `.mise.toml` configuration file specifies which tools to install
3. During build, `mise install` automatically downloads and installs all configured tools
4. Tools are installed to the user's home directory and added to PATH
5. The mise cache and data directories are declared as volumes for persistence

To modify the installed tools, update the `.mise.toml` file before building the image.

## DevContainer Configuration Guide

### Using with VS Code Dev Containers

The base image can be used directly in VS Code Dev Containers with a `devcontainer.json` file. Here are common configuration patterns:

#### Basic Configuration

```json
{
  "name": "Basic Development Container",
  "image": "ghcr.io/onezerocompany/base:latest",
  "customizations": {
    "vscode": {
      "settings": {
        "terminal.integrated.shell.linux": "/bin/zsh"
      }
    }
  }
}
```

#### Advanced Configuration with Custom Tools

```json
{
  "name": "Advanced Development Container",
  "image": "ghcr.io/onezerocompany/base:latest",
  "features": {
    "ghcr.io/devcontainers/features/python:1": {
      "version": "3.11"
    },
    "ghcr.io/devcontainers/features/rust:1": {
      "version": "latest"
    }
  },
  "customizations": {
    "vscode": {
      "settings": {
        "terminal.integrated.shell.linux": "/bin/zsh",
        "python.defaultInterpreterPath": "/usr/bin/python3"
      },
      "extensions": [
        "ms-python.python",
        "rust-lang.rust-analyzer"
      ]
    }
  },
  "remoteEnv": {
    "MISE_CACHE_DIR": "/tmp/mise-cache"
  },
  "postCreateCommand": "mise install && echo 'Container ready!'"
}
```

### Configuration Options

#### Image Tag

| Image Tag | Description | Use Case |
|-----------|-------------|----------|
| `base:latest` | Comprehensive development environment | General development work |

#### Build Arguments

| Argument | Default | Description | Example |
|----------|---------|-------------|---------|
| `USERNAME` | `zero` | Container user name | `"USERNAME": "developer"` |
| `USER_UID` | `1000` | User ID | `"USER_UID": "1001"` |
| `USER_GID` | `1000` | Group ID | `"USER_GID": "1001"` |

#### Environment Variables

| Variable | Default | Description | Example |
|----------|---------|-------------|---------|
| `MISE_CACHE_DIR` | `$HOME/.cache/mise` | mise cache directory | `"/tmp/mise-cache"` |
| `MISE_DATA_DIR` | `$HOME/.local/share/mise` | mise data directory | `"/tmp/mise-data"` |
| `MISE_TRUSTED_CONFIG_PATHS` | `/` | Trusted config paths | `"/workspaces"` |
| `MISE_YES` | `1` | Auto-confirm mise prompts | `"1"` |

#### Volume Mounts

| Host Path | Container Path | Description |
|-----------|----------------|-------------|
| `mise-cache` | `/home/$USERNAME/.cache/mise` | mise download cache |
| `mise-data` | `/home/$USERNAME/.local/share/mise` | mise installed tools |

#### Ports

| Port | Description | Usage |
|------|-------------|-------|
| `22` | SSH (if enabled) | Remote development |
| `80` | HTTP services | Web development |
| `443` | HTTPS services | Secure web development |
| `3000-3999` | Development servers | Common dev server ports |

### DevContainer JSON Examples

#### Full-Featured Development Environment

```json
{
  "name": "Full Development Environment",
  "image": "ghcr.io/onezerocompany/base:latest",
  "features": {
    "ghcr.io/devcontainers/features/node:1": {
      "nodeGypDependencies": true,
      "version": "lts"
    },
    "ghcr.io/devcontainers/features/python:1": {
      "version": "3.11",
      "installTools": true
    },
    "ghcr.io/devcontainers/features/go:1": {
      "version": "1.21"
    }
  },
  "customizations": {
    "vscode": {
      "settings": {
        "terminal.integrated.shell.linux": "/bin/zsh",
        "terminal.integrated.profiles.linux": {
          "zsh": {
            "path": "/bin/zsh"
          }
        },
        "editor.formatOnSave": true,
        "files.autoSave": "afterDelay"
      },
      "extensions": [
        "ms-python.python",
        "golang.go",
        "ms-vscode.vscode-typescript-next",
        "esbenp.prettier-vscode",
        "ms-vscode.vscode-json"
      ]
    }
  },
  "remoteEnv": {
    "MISE_CACHE_DIR": "/tmp/mise-cache",
    "DEVELOPMENT_MODE": "true"
  },
  "mounts": [
    "source=mise-cache,target=/tmp/mise-cache,type=volume"
  ],
  "forwardPorts": [3000, 8080, 9000],
  "postCreateCommand": "mise install && npm install -g @commitlint/cli",
  "postStartCommand": "echo 'Development environment ready!'",
  "postAttachCommand": "mise current"
}
```

#### Minimal Configuration

```json
{
  "name": "Minimal Development",
  "image": "ghcr.io/onezerocompany/base:latest",
  "customizations": {
    "vscode": {
      "settings": {
        "terminal.integrated.shell.linux": "/bin/zsh"
      }
    }
  }
}
```

### Available Tools and Commands

#### Pre-installed Tools

| Tool | Command | Description |
|------|---------|-------------|
| Starship | `starship` | Cross-shell prompt |
| zoxide | `z`, `zi` | Smart cd command |
| fzf | `fzf` | Fuzzy finder |
| bat | `bat` | Syntax-highlighted cat |
| eza | `eza`, `ls` | Modern ls replacement |
| mise | `mise` | Version manager |
| jq | `jq` | JSON processor |
| curl | `curl` | HTTP client |
| git | `git` | Version control |

#### Shell Aliases

| Alias | Command | Description |
|-------|---------|-------------|
| `ll` | `eza -l` | Long listing |
| `la` | `eza -la` | All files with details |
| `tools` | `mise ls --current` | Show installed tools |
| `cat` | `bat` | Syntax highlighting |
| `ls` | `eza` | Modern ls |

### Troubleshooting

#### Common Issues

1. **Permission Issues**
   ```bash
   # Fix user permissions
   sudo chown -R $USER:$USER /workspaces
   ```

2. **mise Tool Issues**
   ```bash
   # Reinstall mise tools
   mise install
   mise reshim
   ```

3. **Shell Configuration Issues**
   ```bash
   # Reconfigure shells
   /usr/local/bin/configure-shells.sh
   ```

### Best Practices

1. **Use Volume Mounts** for mise cache to speed up container startup
2. **Specify Tool Versions** in your project's `.mise.toml`
3. **Use Features** for language-specific tools rather than installing manually
4. **Configure Ports** for your specific development needs

## Notes
- All mise-managed tools are installed globally for the user during image build
- Shell configurations are applied to both bash and zsh
- The image is designed for development environments, not production
- mise provides reproducible tool installations across all containers