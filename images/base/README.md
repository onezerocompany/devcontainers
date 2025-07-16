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

## Notes

- The DIND variant requires `--privileged` flag when running
- All mise-managed tools are installed globally for the user during image build
- Shell configurations are applied to both bash and zsh
- The image is designed for development environments, not production
- mise provides reproducible tool installations across all containers