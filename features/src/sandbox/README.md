# Sandbox

Sets up a sandboxed environment with network firewall restrictions to limit outbound connections.

## Features

This DevContainer feature provides:

1. **Network Firewall** - Restricts outbound connections to only essential services:
   - Anthropic services (claude.ai, anthropic.com)
   - Package managers (npm, bun, deno, pip, etc.)
   - Development tools (GitHub, Linear, JSR)
   - Blocks all other outbound traffic

2. **Configurable Domain Whitelist** - Add custom domains to allow specific services

3. **Container Security** - Properly configured iptables rules with NET_ADMIN capability

## Usage

Add this feature to your `devcontainer.json`:

```json
{
  "features": {
    "ghcr.io/onezerocompany/devcontainers/features/sandbox": {}
  }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enableFirewall | boolean | true | Enable network firewall restrictions |
| additionalAllowedDomains | string | "" | Comma-separated list of additional domains to allow |
| user | string | "zero" | User to configure sandbox for |

## Example with custom options

```json
{
  "features": {
    "ghcr.io/onezerocompany/devcontainers/features/sandbox": {
      "enableFirewall": true,
      "additionalAllowedDomains": "custom-api.example.com,another-service.com",
      "user": "vscode"
    }
  }
}
```

## Allowed Network Connections

When the firewall is enabled, only connections to these domains are allowed:

### Core Services
- `*.anthropic.com`, `*.claude.ai` - AI services
- `github.com`, `api.github.com` - Git operations
- `*.linear.app` - Project management

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
- Linux kernel with iptables and ipset support

## Troubleshooting

### Firewall not working
- Check if the container has `NET_ADMIN` capability
- Verify the firewall script ran: check `/usr/local/share/sandbox/init-firewall.sh`
- Look for firewall logs in the container output

### Additional domains needed
Use the `additionalAllowedDomains` option to whitelist extra domains:

```json
"additionalAllowedDomains": "internal-api.company.com,cdn.example.com"
```

### Testing firewall rules
The firewall initialization script automatically tests connectivity to verify it's working properly.