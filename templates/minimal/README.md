# Minimal DevContainer Template

The absolute minimal configuration needed to run a development container.

## What's Included

- **Base Image**: `ghcr.io/onezerocompany/devcontainer:latest`
- **Shell**: ZSH with Starship prompt (default)
- **Tools**: All tools from the devcontainer image
- **VS Code**: Pre-configured for development

## Usage

Copy the `devcontainer.json` file to your project's `.devcontainer` directory:

```bash
mkdir -p .devcontainer
cp /path/to/templates/minimal/devcontainer.json .devcontainer/
```

## Customization Options

You can extend this minimal configuration by adding:

### VS Code Settings

```json
{
  "name": "Minimal DevContainer",
  "image": "ghcr.io/onezerocompany/devcontainer:latest",
  "customizations": {
    "vscode": {
      "settings": {
        "terminal.integrated.shell.linux": "/bin/zsh"
      }
    }
  }
}
```

### Extensions

```json
{
  "name": "Minimal DevContainer",
  "image": "ghcr.io/onezerocompany/devcontainer:latest",
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-vscode.vscode-typescript-next"
      ]
    }
  }
}
```

### Post-Create Command

```json
{
  "name": "Minimal DevContainer",
  "image": "ghcr.io/onezerocompany/devcontainer:latest",
  "postCreateCommand": "echo 'Welcome to your dev container!'"
}
```

## When to Use This Template

Use this minimal template when:
- You want the simplest possible setup
- You don't need any special features or tools
- You're testing DevContainers for the first time
- You plan to customize everything yourself

## Next Steps

For more features, consider:
- [Basic Template](../basic/) - Includes common settings
- [Node.js Template](../node/) - For JavaScript/TypeScript development
- [Python Template](../python/) - For Python development
- [Full-Stack Template](../fullstack/) - For complex applications