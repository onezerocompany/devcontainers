# Claude Code

Sets up a sandboxed environment for Claude Code with persistent state and network restrictions.

## Features

This DevContainer feature provides:

1. **Claude Code CLI** - Automatically installs the `claude-code` command-line interface via npm

2. **Persistent Volume Mounts** - Maintains Claude Code state across container rebuilds:
   - `~/.claude` - Authentication and session data
   - `~/.anthropic` - API configurations
   - `~/.config/claude-code` - User settings

3. **Network Firewall** - Restricts outbound connections to only essential services:
   - Anthropic services (claude.ai, anthropic.com)
   - Package managers (npm, bun, deno, pip, etc.)
   - Development tools (GitHub, Linear, JSR)
   - Blocks all other outbound traffic

## Usage

Add this feature to your `devcontainer.json`:

```json
{
  "features": {
    "ghcr.io/onezerocompany/devcontainers/features/claude-code": {}
  }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enableFirewall | boolean | true | Enable network firewall restrictions |
| additionalAllowedDomains | string | "" | Comma-separated list of additional domains to allow |
| persistentVolumes | boolean | true | Mount persistent volumes for Claude Code state |
| user | string | "zero" | User to configure Claude Code for |

## Example with custom options

```json
{
  "features": {
    "ghcr.io/onezerocompany/devcontainers/features/claude-code": {
      "enableFirewall": true,
      "additionalAllowedDomains": "custom-api.example.com,another-service.com",
      "persistentVolumes": true,
      "user": "vscode"
    }
  }
}
```

## Allowed Network Connections

When the firewall is enabled, only connections to these domains are allowed:

### Core Services
- `*.anthropic.com`, `*.claude.ai` - Claude Code functionality
- `github.com`, `api.github.com` - Git operations
- `*.linear.app` - Linear project management

### Package Managers
- `registry.npmjs.org` - npm packages
- `bun.sh` - Bun runtime
- `deno.land`, `deno.com` - Deno runtime
- `jsr.io` - JavaScript Registry
- `pypi.org` - Python packages
- `rubygems.org` - Ruby gems
- `crates.io` - Rust packages

### Local Networks
- All localhost connections
- Private IP ranges (10.x, 172.16.x, 192.168.x)

## Requirements

- Container must have `NET_ADMIN` capability for firewall rules
- Host system must support bind mounts for persistent volumes

## Troubleshooting

### Firewall not working
- Check if the container has `NET_ADMIN` capability
- Verify the firewall script ran: check `/usr/local/share/claude-code/init-firewall.sh`
- Look for firewall logs in the container output

### Volume mounts not persisting
- Ensure the host directories exist and have proper permissions
- Check that Docker/Podman has access to bind mount from your home directory

### Additional domains needed
Use the `additionalAllowedDomains` option to whitelist extra domains:

```json
"additionalAllowedDomains": "internal-api.company.com,cdn.example.com"
```