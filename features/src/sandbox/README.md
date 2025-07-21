# Sandbox Network Filter

A development container feature that provides network traffic filtering for sandboxed environments with domain rule support. This feature is designed to control and restrict outbound network traffic according to user-defined rules while allowing Docker service communication.

## Features

- **Domain-based filtering**: Support for subdomain, full domain, and wildcard rules (e.g., `*.example.com`)
- **DNS-level blocking**: Uses hosts file manipulation for efficient domain blocking
- **iptables integration**: Additional packet filtering for comprehensive network control
- **Docker compatibility**: Preserves communication with Docker Compose services
- **Immutable configuration**: Prevents runtime modification of filtering rules
- **Flexible policies**: Configurable default allow/block behavior
- **Logging support**: Optional logging of blocked connection attempts

## Usage

```json
{
  "features": {
    "ghcr.io/onezerocompany/features/sandbox": {
      "allowedDomains": "api.github.com,*.openai.com",
      "blockedDomains": "*.facebook.com,*.twitter.com",
      "defaultPolicy": "block",
      "allowDockerNetworks": true,
      "immutableConfig": true
    }
  }
}
```

## Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `allowedDomains` | string | `""` | Comma-separated list of allowed domains (supports wildcards) |
| `blockedDomains` | string | `"*.facebook.com,*.twitter.com,*.instagram.com,*.tiktok.com,*.youtube.com"` | Comma-separated list of blocked domains |
| `defaultPolicy` | string | `"block"` | Default policy for unlisted domains (`"allow"` or `"block"`) |
| `allowDockerNetworks` | boolean | `true` | Allow traffic to Docker internal networks |
| `allowLocalhost` | boolean | `true` | Allow traffic to localhost and 127.0.0.1 |
| `immutableConfig` | boolean | `true` | Make configuration immutable after setup |
| `logBlocked` | boolean | `true` | Log blocked connections for debugging |

## How It Works

The sandbox feature implements multi-layered network filtering:

1. **DNS Filtering**: Modifies `/etc/hosts` to redirect blocked domains to localhost
2. **iptables Rules**: Creates packet filtering rules for comprehensive traffic control
3. **Docker Network Preservation**: Allows communication with Docker services by permitting traffic to private network ranges
4. **Immutable Enforcement**: Optional protection against runtime configuration changes

## Domain Rule Formats

- **Exact domain**: `example.com` - blocks exactly `example.com`
- **Wildcard**: `*.example.com` - blocks all subdomains of `example.com`
- **Multiple domains**: `"domain1.com,*.domain2.com,domain3.com"`

## Network Ranges

When `allowDockerNetworks` is enabled, the following ranges are permitted:
- `172.16.0.0/12` - Docker default bridge networks
- `10.0.0.0/8` - Docker custom networks
- `192.168.0.0/16` - Local networks

## Example Configurations

### Strict LLM Sandbox
```json
{
  "features": {
    "ghcr.io/onezerocompany/features/sandbox": {
      "allowedDomains": "api.openai.com",
      "blockedDomains": "",
      "defaultPolicy": "block",
      "allowDockerNetworks": true,
      "allowLocalhost": false,
      "immutableConfig": true
    }
  }
}
```

### Development Environment with Social Media Blocking
```json
{
  "features": {
    "ghcr.io/onezerocompany/features/sandbox": {
      "allowedDomains": "*.github.com,*.stackoverflow.com,*.npmjs.com",
      "blockedDomains": "*.facebook.com,*.twitter.com,*.reddit.com",
      "defaultPolicy": "allow",
      "allowDockerNetworks": true,
      "logBlocked": true
    }
  }
}
```

## Testing Network Filtering

After container startup, you can test the filtering:

```bash
# Test DNS blocking
nslookup facebook.com  # Should resolve to 127.0.0.1

# Check iptables rules
iptables -L SANDBOX_OUTPUT

# View configuration
cat /etc/sandbox/config

# Check logs (if logging enabled)
dmesg | grep SANDBOX_BLOCKED
```

## Limitations

- DNS filtering relies on applications respecting system hosts file
- Some applications may use their own DNS resolution
- iptables rules require privileged container mode
- Domain wildcards are implemented at the DNS level only

## Security Notes

This feature is designed for development container sandboxing and should not be considered a complete security solution. It provides a reasonable barrier for containing automated tools and scripts but may not prevent determined attempts to bypass restrictions.