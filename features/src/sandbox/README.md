# Sandbox Network Filter

A development container feature that provides network traffic filtering for sandboxed environments using iptables. This feature is designed to control and restrict outbound network traffic according to user-defined rules while allowing Docker service communication. It can automatically allow domains from Claude Code WebFetch permissions.

## Features

- **iptables-based filtering**: Simple and reliable packet filtering for network control
- **Docker compatibility**: Preserves communication with Docker Compose services
- **Claude Code integration**: Automatically allows domains from Claude Code WebFetch permissions
- **Immutable configuration**: Prevents runtime modification of filtering rules
- **Flexible policies**: Configurable default allow/block behavior
- **Logging support**: Optional logging of blocked connection attempts

## Usage

```json
{
  "features": {
    "ghcr.io/onezerocompany/features/sandbox": {
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
| `defaultPolicy` | string | `"block"` | Default policy for external traffic (`"allow"` or `"block"`) |
| `allowDockerNetworks` | boolean | `true` | Allow traffic to Docker internal networks |
| `allowLocalhost` | boolean | `true` | Allow traffic to localhost and 127.0.0.1 |
| `immutableConfig` | boolean | `true` | Make configuration immutable after setup |
| `logBlocked` | boolean | `true` | Log blocked connections for debugging |
| `allowClaudeWebFetchDomains` | boolean | `true` | Automatically allow domains from Claude Code WebFetch permissions |
| `claudeSettingsPaths` | string | `".claude/settings.json,.claude/settings.local.json,~/.claude/settings.json"` | Comma-separated list of paths to Claude settings files (relative paths are resolved from workspace root) |

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

The sandbox feature implements network filtering using iptables:

1. **iptables Rules**: Creates packet filtering rules for comprehensive traffic control
2. **Docker Network Preservation**: Allows communication with Docker services by permitting traffic to private network ranges
3. **Claude Code Integration**: Reads Claude settings files to extract WebFetch domain permissions and resolves them to IP addresses
4. **DNS Resolution**: Allows DNS queries (port 53) to enable name resolution
5. **Established Connections**: Permits established and related connections for proper network functionality
6. **Immutable Enforcement**: Optional protection against runtime configuration changes

## Network Ranges

When `allowDockerNetworks` is enabled, the following ranges are permitted:
- `172.16.0.0/12` - Docker default bridge networks
- `10.0.0.0/8` - Docker custom networks
- `192.168.0.0/16` - Local networks

## Claude Code Integration

When `allowClaudeWebFetchDomains` is enabled, the feature will:

1. Read Claude settings files from the specified paths (relative paths are resolved from `/workspace`)
2. Extract WebFetch domain rules like `"WebFetch(domain:github.com)"` or `"WebFetch(domain:*.github.com)"`
3. Resolve domains to IP addresses at container startup
4. Add iptables rules to allow traffic to those IPs

This ensures that domains Claude Code is allowed to fetch are also accessible through the network sandbox.

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
      "allowDockerNetworks": true,
      "allowLocalhost": false,
      "allowClaudeWebFetchDomains": true,
      "immutableConfig": true
    }
  }
}
```

### Development Environment with External Access
```json
{
  "features": {
    "ghcr.io/onezerocompany/features/sandbox": {
      "defaultPolicy": "allow",
      "allowDockerNetworks": true,
      "logBlocked": false
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

## Testing Network Filtering

After container startup, you can test the filtering:

```bash
# Check iptables rules
iptables -L SANDBOX_OUTPUT -n -v

# View configuration
cat /etc/sandbox/config

# Check logs (if logging enabled and default policy is block)
dmesg | grep SANDBOX_BLOCKED

# Test external connectivity
curl -I https://example.com  # Will be blocked if defaultPolicy="block"

# Test Docker network connectivity
# Should work if allowDockerNetworks=true
ping another-container
```

## Limitations

- iptables rules require privileged container mode
- This provides IP-level filtering only (no domain-based filtering)
- Claude WebFetch domain resolution happens at container startup - dynamic IP changes require container restart
- Wildcard domains (*.example.com) are resolved as the base domain (example.com)
- Some applications may attempt to bypass system network configuration

## Security Notes

This feature is designed for development container sandboxing and should not be considered a complete security solution. It provides a reasonable barrier for containing network traffic but may not prevent determined attempts to bypass restrictions.