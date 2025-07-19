# Starship Prompt (starship)

A minimal, blazing-fast, and infinitely customizable prompt for any shell.

## Example Usage

```json
"features": {
    "ghcr.io/onezerocompany/devcontainers/features/starship:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Version of Starship to install. Use 'latest' for the most recent version. | string | latest |
| configPath | Path to a custom starship.toml configuration file | string | - |

## Default Configuration

This feature includes a default configuration that provides a clean, minimal prompt with:
- A purple "dev" badge
- Username display
- Current directory on the right side
- Special formatting for git repositories

## Custom Configuration

To use a custom Starship configuration, provide a path to your configuration file:

```json
"features": {
    "ghcr.io/onezerocompany/devcontainers/features/starship:1": {
        "configPath": ".devcontainer/starship.toml"
    }
}
```

## Supported Shells

This feature automatically configures Starship for:
- Bash
- Zsh

## OS Support

This feature supports:
- Debian/Ubuntu
- Alpine Linux
- Other Linux distributions with bash/zsh

---

_Note: This file was auto-generated from the devcontainer-feature.json. Add additional notes to a `NOTES.md`._