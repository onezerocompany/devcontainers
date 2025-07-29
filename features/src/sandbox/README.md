# Sandbox Network Filter

A development container feature that provides network traffic filtering for sandboxed environments using DNS-based blocking via dnsmasq. This feature is designed to control and restrict outbound network traffic according to user-defined rules with true wildcard domain support. It can automatically allow domains from Claude Code WebFetch permissions.

## Features

- **DNS-based filtering**: Efficient domain filtering using dnsmasq with native wildcard support
- **True wildcard support**: Native support for wildcard domains (*.example.com)
- **Claude Code integration**: Automatically allows domains from Claude Code WebFetch permissions
- **Immutable configuration**: Prevents runtime modification of filtering rules
- **Flexible policies**: Configurable default allow/block behavior
- **Query logging**: Optional logging of DNS queries for debugging

## Usage

```json
{
  "features": {
    "ghcr.io/onezerocompany/features/sandbox": {
      "defaultPolicy": "block",
      "allowedDomains": "github.com,*.github.com",
      "blockedDomains": "*.facebook.com,*.twitter.com",
      "immutableConfig": true
    }
  }
}
```

## Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `defaultPolicy` | string | `"block"` | Default policy for DNS resolution (`"allow"` or `"block"`) |
| `allowedDomains` | string | `""` | Comma-separated list of domains to explicitly allow (supports wildcards like *.example.com) |
| `blockedDomains` | string | `""` | Comma-separated list of domains to explicitly block (supports wildcards like *.example.com) |
| `immutableConfig` | boolean | `true` | Make configuration immutable after setup |
| `logQueries` | boolean | `true` | Log DNS queries for debugging |
| `allowClaudeWebFetchDomains` | boolean | `true` | Automatically allow domains from Claude Code WebFetch permissions |
| `claudeSettingsPaths` | string | `".claude/settings.json,.claude/settings.local.json,~/.claude/settings.json"` | Comma-separated list of paths to Claude settings files (relative paths are resolved from workspace root) |
| `allowCommonDevelopment` | boolean | `true` | Allow common development domains (GitHub, npm, PyPI, etc.) |

## Initialization

The sandbox network filter automatically installs an initialization hook at `/usr/local/share/devcontainer-init.d/50-sandbox.sh`.

- **OneZero base image**: Automatically runs all init.d scripts on container startup
- **Other images**: Add this to your entrypoint to run init.d scripts:
  ```bash
  if [ -d /usr/local/share/devcontainer-init.d ]; then
      for init_script in /usr/local/share/devcontainer-init.d/*.sh; do
          [ -r "$init_script" ] && . "$init_script"
      done
  fi
  ```

## How It Works

The sandbox feature implements network filtering using DNS-based blocking via dnsmasq:

1. **DNS Server**: Runs a local dnsmasq DNS server that intercepts all DNS queries
2. **Domain Filtering**: Blocks or allows domains at the DNS resolution level
3. **Wildcard Support**: Native support for wildcard domains (*.example.com) without complex IP resolution
4. **Claude Code Integration**: Reads Claude settings files to extract WebFetch domain permissions
5. **Default Policies**: Configurable default allow/block behavior with explicit overrides
6. **Immutable Enforcement**: Optional protection against runtime configuration changes

## DNS Filtering Logic

The DNS filtering works as follows:
- **Block Policy**: All domains resolve to 127.0.0.1 (blocked) except explicitly allowed domains
- **Allow Policy**: All domains resolve normally except explicitly blocked domains
- **Wildcard Domains**: *.example.com blocks/allows all subdomains of example.com
- **Override Priority**: Blocked domains always take precedence over allowed domains

## Claude Code Integration

When `allowClaudeWebFetchDomains` is enabled, the feature will:

1. Read Claude settings files from the specified paths (relative paths are resolved from `/workspace`)
2. Extract WebFetch domain rules like `"WebFetch(domain:github.com)"` or `"WebFetch(domain:*.github.com)"`
3. Add DNS rules to allow those domains to resolve normally
4. Support wildcard domains natively without IP resolution

This ensures that domains Claude Code is allowed to fetch are also accessible through the DNS sandbox.

### Path Resolution
- Relative paths (e.g., `.claude/settings.json`) are resolved from the workspace root
- Absolute paths (e.g., `/home/user/.claude/settings.json`) are used as-is
- Tilde paths (e.g., `~/.claude/settings.json`) are expanded to the user's home directory

### Workspace Detection
The feature automatically detects the workspace folder by checking these environment variables in order:
1. `WORKSPACE_FOLDER` - Custom workspace folder variable
2. `DEVCONTAINER_WORKSPACE_FOLDER` - Set by some devcontainer implementations
3. `VSCODE_WORKSPACE` - VS Code workspace variable
4. `VSCODE_CWD` - VS Code current working directory
5. `PWD` - Current directory (if it contains `.devcontainer`)
6. Default: `/workspace`

### Claude Settings Example
```json
{
  "permissions": {
    "allow": [
      "WebFetch(domain:github.com)",
      "WebFetch(domain:*.github.com)",
      "WebFetch(domain:docs.anthropic.com)"
    ]
  }
}
```

## Example Configurations

### Strict Development Sandbox with Claude Integration
```json
{
  "features": {
    "ghcr.io/onezerocompany/features/sandbox": {
      "defaultPolicy": "block",
      "allowClaudeWebFetchDomains": true,
      "allowCommonDevelopment": true,
      "immutableConfig": true
    }
  }
}
```

### Development Environment with Selective Blocking
```json
{
  "features": {
    "ghcr.io/onezerocompany/features/sandbox": {
      "defaultPolicy": "allow",
      "blockedDomains": "*.facebook.com,*.twitter.com,*.tiktok.com",
      "logQueries": false
    }
  }
}
```

### Custom Claude Settings Paths
```json
{
  "features": {
    "ghcr.io/onezerocompany/features/sandbox": {
      "defaultPolicy": "block",
      "allowClaudeWebFetchDomains": true,
      "claudeSettingsPaths": "/workspace/.claude/settings.json,~/.claude/custom-settings.json"
    }
  }
}
```

## Testing DNS Filtering

After container startup, you can test the filtering:

```bash
# Check dnsmasq configuration
cat /etc/dnsmasq.d/sandbox.conf

# View sandbox configuration
cat /etc/sandbox/config

# Check dnsmasq process
ps aux | grep dnsmasq

# Test DNS resolution (should be blocked if defaultPolicy="block")
nslookup example.com

# Test allowed domain resolution
nslookup github.com  # Should work if in allowed domains

# Check DNS query logs (if logQueries=true)
grep dnsmasq /var/log/syslog
```

## Limitations

- DNS filtering can be bypassed by applications that use hardcoded IP addresses
- Applications that use their own DNS resolution (bypassing system DNS) may not be filtered
- Some applications may cache DNS results, requiring container restart for changes to take effect
- DNS filtering provides application-level blocking but not network-level security

## Security Notes

This feature is designed for development container sandboxing and should not be considered a complete security solution. It provides a reasonable barrier for containing network traffic but may not prevent determined attempts to bypass DNS-based restrictions. For stronger security, consider combining with network-level controls.