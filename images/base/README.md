# DevContainer Base Image

A comprehensive Ubuntu 22.04-based development container image designed for modern development workflows with pre-installed tools and utilities.

## Overview

This base image provides two variants:
- **Standard**: Basic development environment with all essential tools
- **Docker-in-Docker (DIND)**: Includes Docker daemon support for containerized workflows

## Bill of Materials (BOM)

### Base System
- **OS**: Ubuntu 22.04 LTS
- **Architecture**: Multi-arch support (AMD64, ARM64)
- **User**: Configurable non-root user (default: `zero`)

### Package Management
- **apt-fast**: Accelerated package downloads
- **PPAs**:
  - git-core/ppa (latest Git)
  - apt-fast/stable

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

#### Build Tools
- build-essential
- make
- cmake
- binutils
- pkg-config

#### Programming Languages & Runtimes
- Python 3 (minimal)
- Node.js LTS (via mise)
- GCC/G++ 9
- Libraries: libstdc++6, libgcc1

#### Version Control
- Git (latest from PPA)
- GPG/GnuPG 2

#### Container Tools
- skopeo (container image operations)
- Docker CE (DIND variant only)
- supervisor (process management for DIND)

#### Shell & Terminal
- bash (default system shell)
- zsh (user shell)
- Starship prompt
- zoxide (smart cd)
- fzf (fuzzy finder)

#### File Operations
- curl
- wget  
- tar
- zip/unzip
- xz-utils
- jq (JSON processor)
- bat (syntax-highlighted cat)
- eza (modern ls)

#### Text Editors
- nano
- vim

#### Security & Authentication
- sudo (passwordless for user)
- ca-certificates
- gnome-keyring
- libssl3
- libgssapi-krb5-2

#### Development Libraries
- libcurl4-openssl-dev
- libxml2-dev
- libz3-dev
- zlib1g/zlib1g-dev
- libicu70
- libedit2
- libsqlite3-0
- libpython3.8
- libglu1-mesa
- libc6/libc6-dev

#### System Utilities
- lsb-release
- tzdata
- iptables (legacy mode)
- supervisor (DIND variant)

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
- **entrypoint.sh**: Container entry point handling shell initialization and Docker daemon startup for DIND
- **configure-shells.sh**: Shell configuration setup for bash and zsh
- **install-packages.sh**: Package installation script
- **install-docker.sh**: Docker installation (DIND only)
- **common-utils.sh**: Shared utilities for path management and Docker functions
- **modprobe**: Kernel module loading wrapper (DIND only)

### Volumes
- `/home/$USERNAME/.cache/mise` - mise download cache
- `/home/$USERNAME/.local/share/mise` - mise installed tools and data
- `/var/lib/docker` (DIND variant only)

### Supervisor Configuration (DIND only)
- Docker daemon management via supervisor
- Automatic Docker service startup

## Usage

### Building the Image

```bash
# Standard variant
docker build --target standard -t devcontainer-base:standard .

# Docker-in-Docker variant  
docker build --target dind -t devcontainer-base:dind .
```

### Build Arguments
- `USERNAME`: User name (default: zero)
- `USER_UID`: User ID (default: 1000)
- `USER_GID`: Group ID (default: same as UID)

### Running Containers

```bash
# Standard variant
docker run -it devcontainer-base:standard

# With mise cache volumes for persistence
docker run -it \
  -v mise-cache:/home/zero/.cache/mise \
  -v mise-data:/home/zero/.local/share/mise \
  devcontainer-base:standard

# DIND variant (requires privileged mode)
docker run -it --privileged devcontainer-base:dind
```

## Features

### Multi-stage Build
- Optimized layer caching
- Separate standard and DIND variants
- Minimal final image size

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

### Container Development (DIND)
- Full Docker daemon support
- Supervisor-managed Docker service
- Volume for Docker data persistence
- Privileged mode required

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

#### Docker-in-Docker Configuration

```json
{
  "name": "Docker-in-Docker Development",
  "image": "ghcr.io/onezerocompany/base:dind",
  "runArgs": ["--privileged"],
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

#### Image Variants

| Variant | Image Tag | Description | Use Case |
|---------|-----------|-------------|----------|
| Standard | `base:latest` | Basic development environment | General development work |
| DIND | `base:dind` | Includes Docker daemon | Container development, CI/CD |

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
| `docker-data` | `/var/lib/docker` | Docker data (DIND only) |

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

#### Docker-in-Docker with Custom Configuration

```json
{
  "name": "Docker Development Environment",
  "image": "ghcr.io/onezerocompany/base:dind",
  "runArgs": [
    "--privileged",
    "--network=host"
  ],
  "features": {
    "ghcr.io/devcontainers/features/docker-outside-of-docker:1": {}
  },
  "customizations": {
    "vscode": {
      "settings": {
        "terminal.integrated.shell.linux": "/bin/zsh",
        "docker.dockerPath": "/usr/bin/docker"
      },
      "extensions": [
        "ms-azuretools.vscode-docker",
        "ms-vscode-remote.remote-containers"
      ]
    }
  },
  "remoteEnv": {
    "DOCKER_HOST": "unix:///var/run/docker.sock"
  },
  "mounts": [
    "source=/var/run/docker.sock,target=/var/run/docker.sock,type=bind"
  ],
  "postCreateCommand": "docker --version && docker-compose --version"
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

3. **Docker Issues (DIND)**
   ```bash
   # Check Docker status
   sudo supervisorctl status dockerd
   
   # Restart Docker
   sudo supervisorctl restart dockerd
   ```

4. **Shell Configuration Issues**
   ```bash
   # Reconfigure shells
   /usr/local/bin/configure-shells.sh
   ```

### Best Practices

1. **Use Volume Mounts** for mise cache to speed up container startup
2. **Specify Tool Versions** in your project's `.mise.toml`
3. **Use Features** for language-specific tools rather than installing manually
4. **Configure Ports** for your specific development needs
5. **Use DIND Variant** only when you need Docker inside the container

## Notes

- The DIND variant requires `--privileged` flag when running
- All mise-managed tools are installed globally for the user during image build
- Shell configurations are applied to both bash and zsh
- The image is designed for development environments, not production
- mise provides reproducible tool installations across all containers