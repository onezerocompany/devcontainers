# DevContainer Image

A feature-rich development container image built on top of the base image, designed specifically for VS Code Dev Containers with additional security, tooling, and developer experience enhancements.

## Overview

This image extends the base image with:
- VS Code server and web support
- Enhanced security sandbox with network filtering
- Automated shell configuration with Starship prompt
- Docker-in-Docker support detection
- Post-create and post-attach hooks
- Message of the Day (MOTD) generation

## Architecture

```
devcontainer:latest
    └── base:latest (or base:dind)
```

## Features Added on Top of Base Image

### VS Code Integration
- **VS Code CLI**: Official VS Code command-line interface
- **VS Code Server**: Web-based VS Code server for remote development
- **Extension Management**: Automatic installation of workspace-defined extensions
- **Settings Sync**: Applies workspace VS Code settings automatically
- **Web Access**: Serves VS Code on port 13338 with web interface
- **GNOME Keyring Integration**: Secure credential storage for VS Code
- **Initialization Detection**: Creates `/tmp/.devcontainer-init-complete` marker when ready

### Security Sandbox
- **Network Filtering**: IPSet-based firewall restricting outbound connections
- **Allowed Domains**:
  - Anthropic/Claude APIs
  - GitHub and related services
  - Package registries (npm, PyPI, crates.io, etc.)
  - Linear.app
  - Custom domains via `ADDITIONAL_ALLOWED_DOMAINS`
- **Private Network Access**: Maintains access to local/private IP ranges
- **DNS Resolution**: Automatic IP resolution for allowed domains

### Enhanced Shell Experience
- **Starship Prompt**: Pre-configured with custom theme
- **Shell Integration**: Enhanced bash and zsh configurations
- **Debug Tools**: Starship debugging utility included
- **Shell Aliases**:
  - `cat` → `bat` (syntax highlighting)
  - `ls` → `eza` (modern ls replacement)
  - `ll` → `eza -l` (long listing)
  - `la` → `eza -la` (all files with details)
  - `tools` → `mise ls --current` (show installed tools)

### Developer Tools
- **vscode-kit**: All-in-one VS Code management tool
  - `vscode-kit install`: Install VS Code components
  - `vscode-kit setup`: Configure extensions and settings
  - `vscode-kit start`: Launch VS Code server
- **init-sandbox**: Initialize security sandbox (optional)
- **debug-starship**: Troubleshoot Starship prompt issues

### Lifecycle Hooks
- **post-create**: Runs after container creation
- **post-attach**: Runs when attaching to container
- **Custom MOTD**: Generated message of the day

## Bill of Materials (Additions to Base)

### System Packages
- ipset (network filtering)
- dnsutils (DNS resolution tools)
- libcap2-bin (capability management)

### Scripts and Tools
- `/usr/local/bin/vscode-kit` - VS Code management
- `/usr/local/bin/init-sandbox` - Security sandbox initialization
- `/usr/local/bin/devcontainer-entrypoint` - Enhanced entrypoint
- `/usr/local/bin/post-create` - Post-creation hook
- `/usr/local/bin/post-attach` - Post-attachment hook
- `/usr/local/bin/debug-starship` - Starship debugging
- `/usr/local/share/sandbox/init-firewall.sh` - Firewall setup
- `motd-gen.sh` - Message of the Day generator (used during build)

### Configuration Files
- `~/.config/starship.toml` - Starship prompt configuration
- `/etc/motd` - Message of the day
- `/etc/sudoers.d/sandbox` - Sandbox sudo permissions

### VS Code Directories
- `~/.vscode-install/` - VS Code installation directory
- `~/.vscode-server/` - VS Code server data
- `~/.vscode-server/extensions/` - Installed extensions

## Usage

### Building the Image

```bash
# Standard devcontainer (based on base:latest)
docker build \
  --build-arg BASE_IMAGE_TAG=latest \
  -t devcontainer:latest .

# Docker-in-Docker devcontainer (based on base:dind)
docker build \
  --build-arg BASE_IMAGE_TAG=dind \
  --build-arg DIND=true \
  -t devcontainer:dind .
```

### Build Arguments
- `BASE_IMAGE_REGISTRY`: Base image registry (default: ghcr.io/onezerocompany)
- `BASE_IMAGE_NAME`: Base image name (default: base)
- `BASE_IMAGE_TAG`: Base image tag (default: latest)
- `DIND`: Enable Docker-in-Docker variant (default: false)
- `USERNAME`: User name (inherited from base, default: zero)

### Running the Container

```bash
# Basic usage
docker run -it devcontainer:latest

# With workspace mounted
docker run -it -v $(pwd):/workspaces/project devcontainer:latest

# With VS Code web access
docker run -it -p 13338:13338 devcontainer:latest

# With security sandbox enabled
docker run -it --cap-add=NET_ADMIN devcontainer:latest
```

### Environment Variables

#### VS Code Configuration
- `VSCODE_PORT`: VS Code server port (default: 13338)
- `WORKSPACE_DIR`: Workspace directory path (default: /workspaces)
- `VSCODE_SERVER_DIR`: VS Code server data directory (default: ~/.vscode-server)
- `VSCODE_KEYRING_PASS`: Password for GNOME keyring integration (default: vscode-keyring-pass)
- `VSCODE_LOG_PATH`: VS Code server log location (default: /tmp/vscode-server.log)

#### Sandbox Configuration
- `ADDITIONAL_ALLOWED_DOMAINS`: Comma-separated list of additional domains to allow through firewall
- `DEVCONTAINER_SANDBOX_ENABLED`: Enable sandbox on container start (true/false)
- `DEVCONTAINER_SANDBOX_FIREWALL`: Enable firewall within sandbox (true/false)
- `DEVCONTAINER_SANDBOX_ALLOWED_DOMAINS`: Initial allowed domains (comma-separated)
- `ENABLE_SANDBOX_FIREWALL`: Alternative flag to enable firewall (true/false)

## Security Sandbox

The security sandbox provides network-level isolation with immutable state management.

### Sandbox State Management
The sandbox uses an immutable state system stored in `/var/lib/devcontainer-sandbox/`:
- `enabled` - Sandbox enablement state (read-only after initialization)
- `firewall` - Firewall configuration state
- `domains` - Allowed domains configuration

These files are created once at container startup based on environment variables and cannot be modified during the container's lifetime.

### Enabling the Sandbox
```bash
# Run inside container
init-sandbox
```

### Requirements
- Container must have `NET_ADMIN` capability
- Run with `--cap-add=NET_ADMIN` when starting container

### Allowed Connections
- All loopback traffic
- DNS queries (port 53)
- Established connections
- Pre-configured allowed domains
- Custom domains via environment variable

### Pre-configured Allowed Domains
The firewall allows connections to these domains by default:
- **Anthropic/Claude**: anthropic.com, api.anthropic.com, claude.ai
- **GitHub**: github.com, api.github.com, raw.githubusercontent.com, objects.githubusercontent.com, codeload.github.com, github.githubassets.com
- **Package Managers**: 
  - npm: registry.npmjs.org, registry.yarnpkg.com
  - Bun: bun.sh, install.bun.sh
  - Deno: deno.land, deno.com, jsr.io
  - Python: pypi.org, files.pythonhosted.org
  - Ruby: rubygems.org
  - Rust: crates.io, static.crates.io
- **Linear**: linear.app, api.linear.app, cdn.linear.app
- **Private Networks**: 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16, 127.0.0.0/8

### Adding Custom Domains
```bash
# At container start
docker run -it \
  -e ADDITIONAL_ALLOWED_DOMAINS="example.com,api.example.com" \
  --cap-add=NET_ADMIN \
  devcontainer:latest
```

## VS Code Integration

### Automatic Setup
When used with VS Code Dev Containers:
1. Reads `.devcontainer/devcontainer.json`
2. Installs specified extensions
3. Applies workspace settings
4. Configures VS Code server

### Manual VS Code Server
```bash
# Install VS Code components
vscode-kit install

# Setup extensions and settings
vscode-kit setup

# Start VS Code server
vscode-kit start

# Access at http://localhost:13338
```

## Lifecycle Management

### Post-Create Hook
Runs once when container is first created:
- Initializes user environment
- Sets up development tools
- Configures workspace

### Post-Attach Hook  
Runs each time you attach to the container:
- Refreshes environment
- Updates dynamic configurations
- Displays MOTD

## Troubleshooting

### Starship Prompt Issues
```bash
debug-starship
```

### VS Code Server Issues
```bash
# Check logs
cat /tmp/vscode-server.log

# Reinstall VS Code
vscode-kit install
```

### Sandbox Connectivity Issues
```bash
# Check firewall rules
sudo iptables -L OUTPUT -n

# Test connectivity
curl -v https://api.github.com
```

## Notes

- The image inherits all features from the base image
- Security sandbox is optional and requires NET_ADMIN capability
- VS Code server data persists in the container
- Extensions are installed per-workspace based on devcontainer.json
- DIND variant requires privileged mode (inherited from base)