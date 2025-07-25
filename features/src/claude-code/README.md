# Claude Code

Installs Claude Code CLI via mise (as an npm package), including configuration directories and environment variables.

## Example Usage

```json
"features": {
    "ghcr.io/onezerocompany/features/claude-code:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| claudeCodeVersion | Claude Code version to install via mise | string | latest |
| configDir | Claude Code config directory path. If empty, defaults to /home/$USER/.claude | string | |
| installGlobally | Install Claude Code globally for all users | boolean | true |

## Customizations

### VS Code Extensions

- `Anthropic.claude-code`

## Environment Variables

This feature sets the following environment variables:

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

This feature requires:
- **mise**: Must be available in the container (use the mise-en-place feature)

This feature installs after:
- `ghcr.io/onezerocompany/features/modern-shell` (if used)
- `ghcr.io/onezerocompany/features/mise-en-place` (required)

## Tools Installed

- **Claude Code**: Anthropic's CLI for Claude (version specified by `claudeCodeVersion`)

## Example Configurations

### Basic Usage
```json
"features": {
    "ghcr.io/onezerocompany/features/claude-code:1": {}
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

- Claude Code is installed globally via mise as an npm package
- This feature requires mise to be pre-installed in the container (use the mise-en-place feature)
- A global wrapper script is created at /usr/local/bin/claude-code for easy access
- The feature creates a configuration directory for Claude Code
- Environment variables are exported via `/etc/profile.d/claude-code.sh`