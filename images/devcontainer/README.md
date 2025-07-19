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
- **Network Filtering**: DNS-based filtering using Blocky DNS proxy
- **Allowed Domains**:
  - Anthropic/Claude APIs
  - GitHub and related services
  - Package registries (npm, PyPI, crates.io, etc.)
  - Linear.app
  - Custom domains via `SANDBOX_ALLOWED_DOMAINS`
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
- `SANDBOX_ENABLED`: Enable sandbox mode with firewall on container start (true/false)
- `SANDBOX_ALLOWED_DOMAINS`: Comma-separated list of allowed domains for the firewall

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
- For DNS-based filtering to work properly, s6-overlay must be running as the init system
  - In devcontainer.json, set `"overrideCommand": false` to use s6-overlay as init
  - Without s6-overlay as init, DNS filtering will not be active

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
# At container start (domains are set once and become immutable)
docker run -it \
  -e SANDBOX_ALLOWED_DOMAINS="example.com,api.example.com" \
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

## DevContainer Configuration Guide

### Using with VS Code Dev Containers

This is the recommended image for VS Code Dev Containers. It provides a complete development environment with VS Code integration, security features, and enhanced developer experience.

#### Basic Configuration

```json
{
  "name": "DevContainer Environment",
  "image": "ghcr.io/onezerocompany/devcontainer:latest",
  "customizations": {
    "vscode": {
      "settings": {
        "terminal.integrated.shell.linux": "/bin/zsh"
      }
    }
  }
}
```

#### With Security Sandbox

```json
{
  "name": "Secure DevContainer",
  "image": "ghcr.io/onezerocompany/devcontainer:latest",
  "containerEnv": {
    "SANDBOX_ENABLED": "true",
    "SANDBOX_ALLOWED_DOMAINS": "example.com,api.example.com"
  },
  "capAdd": ["NET_ADMIN"],
  "runArgs": ["--cap-add=NET_ADMIN"],
  "postCreateCommand": "init-sandbox",
  "customizations": {
    "vscode": {
      "settings": {
        "terminal.integrated.shell.linux": "/bin/zsh"
      }
    }
  }
}
```

#### Docker-in-Docker with VS Code

```json
{
  "name": "Docker DevContainer",
  "image": "ghcr.io/onezerocompany/devcontainer:dind",
  "runArgs": ["--privileged"],
  "customizations": {
    "vscode": {
      "settings": {
        "terminal.integrated.shell.linux": "/bin/zsh",
        "docker.dockerPath": "/usr/bin/docker"
      },
      "extensions": [
        "ms-azuretools.vscode-docker"
      ]
    }
  }
}
```

### Configuration Options

#### Image Variants

| Variant | Image Tag | Description | Use Case |
|---------|-----------|-------------|----------|
| Standard | `devcontainer:latest` | Full dev environment with VS Code | General development |
| DIND | `devcontainer:dind` | Includes Docker daemon | Container development |

#### Build Arguments

| Argument | Default | Description | Example |
|----------|---------|-------------|---------|
| `BASE_IMAGE_REGISTRY` | `ghcr.io/onezerocompany` | Base image registry | Custom registry |
| `BASE_IMAGE_NAME` | `base` | Base image name | Custom base |
| `BASE_IMAGE_TAG` | `latest` | Base image tag | `"dind"` |
| `DIND` | `false` | Enable Docker-in-Docker | `"true"` |
| `USERNAME` | `zero` | Container user name | `"developer"` |

#### Environment Variables

##### VS Code Configuration

| Variable | Default | Description | Example |
|----------|---------|-------------|---------|
| `VSCODE_PORT` | `13338` | VS Code server port | `"8080"` |
| `WORKSPACE_DIR` | `/workspaces` | Workspace directory | `"/app"` |
| `VSCODE_SERVER_DIR` | `~/.vscode-server` | VS Code server data | `"/tmp/vscode"` |
| `VSCODE_KEYRING_PASS` | `vscode-keyring-pass` | Keyring password | Custom password |
| `VSCODE_LOG_PATH` | `/tmp/vscode-server.log` | Log file location | Custom path |

##### Sandbox Configuration

| Variable | Default | Description | Example |
|----------|---------|-------------|---------|
| `SANDBOX_ENABLED` | `false` | Enable sandbox on startup | `"true"` |
| `SANDBOX_ALLOWED_DOMAINS` | `""` | Additional allowed domains | `"example.com,api.example.com"` |

#### Ports

| Port | Description | Usage |
|------|-------------|-------|
| `13338` | VS Code server | Web-based VS Code |
| `3000-3999` | Development servers | Common dev ports |
| `8080` | Alternative web server | HTTP services |

#### Volume Mounts

| Container Path | Description | Recommended Host Mount |
|----------------|-------------|------------------------|
| `/workspaces` | Workspace directory | Project root |
| `~/.vscode-server` | VS Code server data | Named volume |
| `~/.cache/mise` | mise cache | Named volume |
| `~/.local/share/mise` | mise data | Named volume |

#### Capabilities

| Capability | Required For | Description |
|------------|--------------|-------------|
| `NET_ADMIN` | Security sandbox | Network filtering |
| `SYS_ADMIN` | Docker-in-Docker | Container management |

### DevContainer JSON Examples

#### Full-Featured Web Development

```json
{
  "name": "Full-Stack Web Development",
  "image": "ghcr.io/onezerocompany/devcontainer:latest",
  "features": {
    "ghcr.io/devcontainers/features/node:1": {
      "nodeGypDependencies": true,
      "version": "lts"
    },
    "ghcr.io/devcontainers/features/python:1": {
      "version": "3.11"
    }
  },
  "customizations": {
    "vscode": {
      "settings": {
        "terminal.integrated.shell.linux": "/bin/zsh",
        "editor.formatOnSave": true,
        "eslint.enable": true,
        "prettier.enable": true
      },
      "extensions": [
        "ms-vscode.vscode-typescript-next",
        "esbenp.prettier-vscode",
        "dbaeumer.vscode-eslint",
        "bradlc.vscode-tailwindcss",
        "ms-python.python"
      ]
    }
  },
  "containerEnv": {
    "VSCODE_PORT": "13338",
    "SANDBOX_ENABLED": "true",
    "SANDBOX_ALLOWED_DOMAINS": "cdn.jsdelivr.net,unpkg.com"
  },
  "capAdd": ["NET_ADMIN"],
  "runArgs": ["--cap-add=NET_ADMIN"],
  "forwardPorts": [3000, 3001, 8080, 13338],
  "postCreateCommand": "bun install && init-sandbox",
  "postAttachCommand": "echo 'Web development environment ready!'"
}
```

#### Database Development with PostgreSQL

```json
{
  "name": "Database Development",
  "dockerComposeFile": "docker-compose.yml",
  "service": "devcontainer",
  "workspaceFolder": "/workspaces",
  "customizations": {
    "vscode": {
      "settings": {
        "terminal.integrated.shell.linux": "/bin/zsh"
      },
      "extensions": [
        "ckolkman.vscode-postgres",
        "ms-vscode.vscode-json",
        "ms-ossdata.vscode-postgresql"
      ]
    }
  },
  "containerEnv": {
    "SANDBOX_ENABLED": "true",
    "SANDBOX_ALLOWED_DOMAINS": "postgresql.org,postgresapp.com",
    "DATABASE_URL": "postgresql://postgres:postgres@postgres:5432/devdb"
  },
  "capAdd": ["NET_ADMIN"],
  "postCreateCommand": "init-sandbox && bun install",
  "forwardPorts": [5432, 13338]
}
```

#### Containerized Development (DIND)

```json
{
  "name": "Container Development",
  "image": "ghcr.io/onezerocompany/devcontainer:dind",
  "runArgs": ["--privileged"],
  "features": {
    "ghcr.io/devcontainers/features/docker-compose:2": {}
  },
  "customizations": {
    "vscode": {
      "settings": {
        "terminal.integrated.shell.linux": "/bin/zsh",
        "docker.dockerPath": "/usr/bin/docker"
      },
      "extensions": [
        "ms-azuretools.vscode-docker",
        "ms-kubernetes-tools.vscode-kubernetes-tools"
      ]
    }
  },
  "containerEnv": {
    "DOCKER_HOST": "unix:///var/run/docker.sock"
  },
  "forwardPorts": [13338],
  "postCreateCommand": "docker --version && docker-compose --version"
}
```

#### Minimal Configuration

```json
{
  "name": "Minimal DevContainer",
  "image": "ghcr.io/onezerocompany/devcontainer:latest",
  "customizations": {
    "vscode": {
      "settings": {
        "terminal.integrated.shell.linux": "/bin/zsh"
      }
    }
  }
}
```

#### Multi-Service Development

```json
{
  "name": "Multi-Service Development",
  "dockerComposeFile": "docker-compose.yml",
  "service": "devcontainer",
  "workspaceFolder": "/workspaces",
  "customizations": {
    "vscode": {
      "settings": {
        "terminal.integrated.shell.linux": "/bin/zsh"
      },
      "extensions": [
        "ms-vscode.vscode-typescript-next",
        "ckolkman.vscode-postgres",
        "ms-python.python"
      ]
    }
  },
  "containerEnv": {
    "SANDBOX_ENABLED": "true",
    "SANDBOX_ALLOWED_DOMAINS": "redis.io,postgresql.org"
  },
  "capAdd": ["NET_ADMIN"],
  "postCreateCommand": "init-sandbox && bun install",
  "forwardPorts": [3000, 5432, 6379, 13338]
}
```

### Available Tools and Commands

#### VS Code Tools

| Command | Description | Usage |
|---------|-------------|-------|
| `vscode-kit install` | Install VS Code components | Setup VS Code |
| `vscode-kit setup` | Configure extensions/settings | Apply workspace config |
| `vscode-kit start` | Start VS Code server | Launch web interface |
| `code` | VS Code CLI | Open files/folders |

#### Security Tools

| Command | Description | Usage |
|---------|-------------|-------|
| `init-sandbox` | Initialize security sandbox | Enable network filtering |
| `sudo iptables -L OUTPUT -n` | Check firewall rules | Debug connectivity |

#### Debug Tools

| Command | Description | Usage |
|---------|-------------|-------|
| `debug-starship` | Debug Starship prompt | Fix shell issues |
| `cat /tmp/vscode-server.log` | VS Code server logs | Debug VS Code |

### Security Sandbox Configuration

#### Default Allowed Domains

The sandbox allows connections to these domains by default:

**Development Tools:**
- `anthropic.com`, `api.anthropic.com`, `claude.ai`
- `github.com`, `api.github.com`, `raw.githubusercontent.com`
- `linear.app`, `api.linear.app`, `cdn.linear.app`

**Package Managers:**
- `registry.npmjs.org`, `registry.yarnpkg.com`
- `bun.sh`, `install.bun.sh`
- `deno.land`, `deno.com`, `jsr.io`
- `pypi.org`, `files.pythonhosted.org`
- `rubygems.org`
- `crates.io`, `static.crates.io`

**Private Networks:**
- `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`, `127.0.0.0/8`

#### Custom Domain Configuration

```json
{
  "containerEnv": {
    "SANDBOX_ENABLED": "true",
    "SANDBOX_ALLOWED_DOMAINS": "example.com,api.example.com,cdn.example.com"
  }
}
```

### Lifecycle Hooks

#### Post-Create Hook

Automatically runs when the container is first created:
- Initializes user environment
- Sets up development tools
- Configures workspace
- Runs your custom `postCreateCommand`

#### Post-Attach Hook

Runs each time you attach to the container:
- Refreshes environment
- Updates dynamic configurations
- Displays MOTD
- Runs your custom `postAttachCommand`

### Troubleshooting

#### VS Code Issues

1. **VS Code Server Won't Start**
   ```bash
   # Check logs
   cat /tmp/vscode-server.log
   
   # Reinstall VS Code
   vscode-kit install
   ```

2. **Extensions Not Installing**
   ```bash
   # Manually setup extensions
   vscode-kit setup
   
   # Check VS Code server status
   ps aux | grep code-server
   ```

3. **Web Interface Not Accessible**
   ```bash
   # Check if port is forwarded
   netstat -tlnp | grep 13338
   
   # Restart VS Code server
   vscode-kit start
   ```

#### Security Sandbox Issues

1. **Cannot Access External APIs**
   ```bash
   # Check firewall rules
   sudo iptables -L OUTPUT -n
   
   # Test connectivity
   curl -v https://api.github.com
   ```

2. **Package Installation Fails**
   ```bash
   # Add required domains to SANDBOX_ALLOWED_DOMAINS
   # Restart container with updated configuration
   ```

3. **Sandbox Won't Initialize**
   ```bash
   # Check NET_ADMIN capability
   capsh --print | grep NET_ADMIN
   
   # Verify container was started with --cap-add=NET_ADMIN
   ```

#### General Issues

1. **Shell Configuration Problems**
   ```bash
   # Reconfigure shells
   /usr/local/bin/configure-shells.sh
   
   # Debug starship
   debug-starship
   ```

2. **Permission Issues**
   ```bash
   # Fix workspace permissions
   sudo chown -R $USER:$USER /workspaces
   ```

### Best Practices

1. **Use Named Volumes** for VS Code server data persistence
2. **Configure Ports** based on your application needs
3. **Enable Sandbox** for security-sensitive development
4. **Use Docker Compose** for multi-service applications
5. **Specify Extensions** in devcontainer.json for consistency
6. **Set Custom Domains** for sandbox when needed
7. **Use Post-Create Commands** for project-specific setup

### Performance Optimization

1. **Volume Mounts**: Use named volumes for frequently accessed data
2. **Layer Caching**: Leverage Docker layer caching for faster builds
3. **Resource Limits**: Set appropriate CPU/memory limits
4. **Port Forwarding**: Only forward necessary ports

## Notes

- The image inherits all features from the base image
- Security sandbox is optional and requires NET_ADMIN capability
- VS Code server data persists in the container
- Extensions are installed per-workspace based on devcontainer.json
- DIND variant requires privileged mode (inherited from base)