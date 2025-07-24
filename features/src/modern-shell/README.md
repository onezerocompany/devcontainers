# Modern Shell Feature

A comprehensive modern shell environment for development containers with enhanced CLI tools and productivity features.

## Features

This feature provides:

- **Modern CLI Tools**:
  - `eza` - Modern replacement for `ls` with colors and icons
  - `bat` - Syntax-highlighting replacement for `cat`
  - `fd` - User-friendly alternative to `find`
  - `ripgrep` - Blazingly fast alternative to `grep`
  - `zoxide` - Smarter `cd` command that learns your habits

- **Shell Enhancements**:
  - Zsh shell with optional plugins
  - Starship prompt for a beautiful, informative shell prompt
  - Smart aliases for common commands
  - Enhanced tab completions
  - Configurable history

## Installation

```json
{
  "features": {
    "ghcr.io/onezerocompany/features/modern-shell": {}
  }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `zsh_default` | boolean | `true` | Set Zsh as the default shell |
| `auto_cd` | boolean | `true` | Enable auto cd in Zsh (type directory names to cd) |
| `zoxide_cd` | boolean | `false` | Replace cd with zoxide's smart `z` command |
| `starship` | boolean | `true` | Enable Starship prompt |
| `custom_aliases` | string | `""` | Additional custom aliases (semicolon-separated) |
| `zsh_plugins` | enum | `"minimal"` | Zsh plugin preset: none, minimal, or full |
| `shell_history_size` | string | `"10000"` | Number of commands to keep in history |
| `enable_completions` | boolean | `true` | Enable enhanced tab completions |
| `alias_ls` | boolean | `true` | Alias ls commands to eza |
| `alias_cat` | boolean | `true` | Alias cat to bat |
| `alias_find` | boolean | `true` | Alias find to fd |
| `alias_grep` | boolean | `true` | Alias grep to ripgrep (rg) |

## Examples

### Basic Usage
```json
{
  "features": {
    "ghcr.io/onezerocompany/features/modern-shell": {}
  }
}
```

### Enable Zoxide as CD Replacement
```json
{
  "features": {
    "ghcr.io/onezerocompany/features/modern-shell": {
      "zoxide_cd": true
    }
  }
}
```

### Full Featured Setup
```json
{
  "features": {
    "ghcr.io/onezerocompany/features/modern-shell": {
      "zoxide_cd": true,
      "zsh_plugins": "full",
      "custom_aliases": "ll='ls -la';gst='git status';dc='docker compose'"
    }
  }
}
```

### Minimal Setup (No Starship)
```json
{
  "features": {
    "ghcr.io/onezerocompany/features/modern-shell": {
      "starship": false,
      "zsh_plugins": "none"
    }
  }
}
```

### Selective Aliases
```json
{
  "features": {
    "ghcr.io/onezerocompany/features/modern-shell": {
      "alias_ls": true,
      "alias_cat": true,
      "alias_find": false,  // Keep standard find command
      "alias_grep": false,  // Keep standard grep command
      "custom_aliases": "g='git';dc='docker compose';k='kubectl'"
    }
  }
}
```

## Included Aliases

The following aliases are automatically configured:

- `ls` → `eza --color=auto --group-directories-first`
- `ll` → `eza -l --color=auto --group-directories-first`
- `la` → `eza -la --color=auto --group-directories-first`
- `lt` → `eza --tree --color=auto`
- `cat` → `bat --paging=never`
- `find` → `fd`
- `grep` → `rg`

When `zoxide_cd` is enabled:
- `cd` → `z` (smart directory jumping)

## Zsh Plugin Presets

- **none**: No additional plugins
- **minimal**: Syntax highlighting and autosuggestions
- **full**: Includes git, docker, kubectl, and more productivity plugins

## Tips

1. **Zoxide Usage**: After enabling `zoxide_cd`, use `z` to jump to frequently used directories:
   ```bash
   z proj  # Jumps to ~/projects if you've been there before
   ```

2. **Bat Themes**: Change bat's color theme:
   ```bash
   bat --list-themes  # List available themes
   export BAT_THEME="TwoDark"  # Set a theme
   ```

3. **Eza Icons**: If your terminal supports it, enable icons:
   ```bash
   alias ls='eza --icons --color=auto --group-directories-first'
   ```

## Compatibility

- Works with both AMD64 and ARM64 architectures
- Compatible with Debian/Ubuntu-based containers
- Configures both bash and zsh shells
- Sets up both regular user and root environments