# DNS-Based Domain Filtering

This devcontainer now supports DNS-based domain filtering with native wildcard support, providing a more robust and unprivileged alternative to iptables-based filtering.

## Features

- **True wildcard support**: Use `*.example.com` to allow all subdomains
- **Unprivileged operation**: No `NET_ADMIN` capability required
- **DNS-level filtering**: Blocks domains at DNS resolution, not IP level
- **Lightweight**: Uses Blocky, a 19MB DNS proxy designed for containers

## Configuration

### Enable DNS Filtering

Set the following environment variables in your devcontainer.json:

```json
{
  "containerEnv": {
    "DNS_FILTER_ENABLED": "true",
    "DNS_ALLOWED_DOMAINS": "*.example.com,api.another.com"
  }
}
```

### Environment Variables

- `DNS_FILTER_ENABLED`: Set to `"true"` to enable DNS filtering
- `DNS_ALLOWED_DOMAINS`: Comma-separated list of allowed domains (supports wildcards)

### Default Allowed Domains

The following domains are allowed by default:
- `*.anthropic.com`, `*.claude.ai` (Anthropic/Claude)
- `*.github.com`, `*.githubusercontent.com` (GitHub)
- `*.npmjs.org`, `*.yarnpkg.com`, `*.bun.sh`, `*.deno.land` (Package managers)
- `*.pypi.org`, `*.pythonhosted.org`, `*.rubygems.org`, `*.crates.io`
- `*.linear.app` (Linear)
- Local/private networks (10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16, 127.0.0.0/8)

### Wildcard Examples

```bash
# Allow all subdomains of example.com
DNS_ALLOWED_DOMAINS="*.example.com"

# Mix wildcards and specific domains
DNS_ALLOWED_DOMAINS="*.example.com,specific.another.com,*.third.com"

# Multiple domains
DNS_ALLOWED_DOMAINS="*.dev.company.com,*.prod.company.com,external-api.com"
```

## How It Works

1. **Blocky DNS Proxy**: Lightweight DNS proxy runs on port 53
2. **Allowlist-based**: Only explicitly allowed domains resolve
3. **Default Deny**: All other domains return NXDOMAIN
4. **Wildcard Matching**: `*.domain.com` matches all subdomains

## Comparison with Sandbox Mode

| Feature | DNS Filtering | IPTables Sandbox |
|---------|--------------|------------------|
| Wildcard support | ✅ Native | ❌ Manual expansion |
| Privilege required | ❌ None | ✅ NET_ADMIN |
| Dynamic domains | ✅ Yes | ❌ No |
| Performance | ✅ Fast | ✅ Fast |
| Compatibility | ✅ All containers | ⚠️ Requires capabilities |

## Migration from Sandbox

To migrate from `SANDBOX_ALLOWED_DOMAINS` to DNS filtering:

```json
// Old (iptables-based)
{
  "containerEnv": {
    "SANDBOX_ENABLED": "true",
    "SANDBOX_ALLOWED_DOMAINS": "example.com,api.example.com,cdn.example.com"
  },
  "capAdd": ["NET_ADMIN"]
}

// New (DNS-based)
{
  "containerEnv": {
    "DNS_FILTER_ENABLED": "true",
    "DNS_ALLOWED_DOMAINS": "*.example.com"
  }
  // No capAdd needed!
}
```

## Troubleshooting

### Check DNS Filter Status
```bash
# Check if Blocky is running
ps aux | grep blocky

# View Blocky logs
journalctl -u blocky -f

# Test domain resolution
nslookup allowed-domain.com
nslookup blocked-domain.com
```

### Temporarily Disable
```bash
# Restore original DNS
sudo cp /etc/resolv.conf.backup /etc/resolv.conf
```

### Debug Configuration
```bash
# View generated Blocky config
cat /etc/blocky/config.yml
```