# Sandbox Network Filter

A development container feature that provides network traffic filtering for sandboxed environments with domain rule support. This feature is designed to control and restrict outbound network traffic according to user-defined rules while allowing Docker service communication.

## Features

- **Advanced wildcard domain filtering**: Full support for wildcard patterns (e.g., `*.example.com`) using dnsmasq DNS interception
- **DNS-level blocking**: Uses dnsmasq for true wildcard DNS blocking and hosts file manipulation for exact domains
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

The sandbox feature implements multi-layered network filtering with enhanced wildcard support:

1. **DNS Filtering**: Uses dnsmasq DNS server to intercept and block wildcard domain patterns (e.g., `*.example.com` blocks all subdomains)
2. **Hosts File Fallback**: Modifies `/etc/hosts` for exact domain matches and as backup when dnsmasq is unavailable  
3. **iptables Rules**: Creates packet filtering rules for comprehensive traffic control
4. **Docker Network Preservation**: Allows communication with Docker services by permitting traffic to private network ranges
5. **Immutable Enforcement**: Optional protection against runtime configuration changes

## Domain Rule Formats

- **Exact domain**: `example.com` - blocks exactly `example.com`
- **Wildcard**: `*.example.com` - blocks all subdomains of `example.com` (api.example.com, test.example.com, etc.)
- **Multiple domains**: `"domain1.com,*.domain2.com,domain3.com"`

### Wildcard Implementation

The improved wildcard handling uses dnsmasq to provide true DNS-level blocking:
- `*.facebook.com` blocks any subdomain like `api.facebook.com`, `mobile.facebook.com`, `xyz.facebook.com`
- No need to manually specify common subdomains - all possible subdomains are blocked automatically
- Fallback hosts file entries ensure blocking works even if dnsmasq fails to start

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
# Test DNS blocking with wildcards
nslookup api.facebook.com  # Should resolve to 127.0.0.1
nslookup mobile.twitter.com  # Should resolve to 127.0.0.1

# Check dnsmasq is running
systemctl status dnsmasq

# Check dnsmasq configuration
cat /etc/dnsmasq.d/sandbox.conf

# Check iptables rules
iptables -L SANDBOX_OUTPUT

# View configuration
cat /etc/sandbox/config

# Check logs (if logging enabled)
dmesg | grep SANDBOX_BLOCKED
```

## Limitations

- DNS filtering requires applications to respect system DNS configuration
- Some applications may use hardcoded DNS servers or their own DNS resolution
- iptables rules require privileged container mode
- dnsmasq service needs to be running for full wildcard functionality

## Security Notes

This feature is designed for development container sandboxing and should not be considered a complete security solution. It provides a reasonable barrier for containing automated tools and scripts but may not prevent determined attempts to bypass restrictions.