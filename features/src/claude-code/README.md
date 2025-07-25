# Claude Code

Installs Claude Code CLI with Node.js via mise, including configuration directories and environment variables.

## Example Usage

```json
"features": {
    "ghcr.io/onezerocompany/features/claude-code:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| nodeVersion | Node.js version to install via mise (e.g., 'lts', '20', '22.11.0') | string | lts |
| claudeCodeVersion | Claude Code version to install via mise | string | latest |
| configDir | Claude Code config directory path. If empty, defaults to /home/$USER/.claude | string | |
| maxOldSpaceSize | Node.js max-old-space-size in MB for NODE_OPTIONS | string | 8192 |
| installGlobally | Install Node.js and Claude Code globally for all users | boolean | true |

## Customizations

### VS Code Extensions

- `Anthropic.claude-code`

## Environment Variables

This feature sets the following environment variables:

- `NODE_OPTIONS`: Set to `--max-old-space-size=${maxOldSpaceSize}` (default: 8192)
- `CLAUDE_CONFIG_DIR`: Set to the Claude configuration directory path

## Volume Mounts

For persistence across container rebuilds, mount these directories:

```json
"mounts": [
    "source=claude-code-config-${devcontainerId},target=/home/zero/.claude,type=volume",
    "source=claude-code-bashhistory-${devcontainerId},target=/commandhistory,type=volume"
]
```

## Dependencies

This feature installs after:
- `ghcr.io/onezerocompany/features/modern-shell` (if used)

## Tools Installed

- **mise**: Modern tool version manager
- **Node.js**: JavaScript runtime (version specified by `nodeVersion`)
- **Claude Code**: Anthropic's CLI for Claude (version specified by `claudeCodeVersion`)

## Example Configurations

### Basic Usage
```json
"features": {
    "ghcr.io/onezerocompany/features/claude-code:1": {}
}
```

### Custom Node Version
```json
"features": {
    "ghcr.io/onezerocompany/features/claude-code:1": {
        "nodeVersion": "20",
        "maxOldSpaceSize": "4096"
    }
}
```

### Custom Config Directory
```json
"features": {
    "ghcr.io/onezerocompany/features/claude-code:1": {
        "configDir": "/opt/claude-config"
    }
}
```

## Notes

- Claude Code and Node.js are installed via mise for consistent version management
- The feature creates a `.mise.toml` file in each user's home directory
- Shell integration is automatically configured for both bash and zsh
- Environment variables are exported via `/etc/profile.d/claude-code.sh`