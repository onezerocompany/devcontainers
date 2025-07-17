# DevContainer Templates

Ready-to-use DevContainer templates for various development scenarios.

## Available Templates

### [Minimal](./minimal/)
The absolute minimal configuration - just the essentials.

```json
{
  "name": "Minimal DevContainer",
  "image": "ghcr.io/onezerocompany/devcontainer:latest"
}
```

**Use when:** You want the simplest possible setup with no customizations.

## How to Use Templates

### Option 1: Direct Copy

```bash
# Copy template to your project
mkdir -p .devcontainer
cp templates/minimal/devcontainer.json .devcontainer/
```

### Option 2: VS Code Command Palette

1. Open VS Code
2. Press `Cmd/Ctrl + Shift + P`
3. Type "Dev Containers: Add Dev Container Configuration Files..."
4. Choose "From a template"

### Option 3: GitHub Template Repository

Fork or use this repository as a template for your projects.

## Template Structure

Each template includes:
- `devcontainer.json` - The main configuration file
- `README.md` - Documentation and usage instructions
- Additional files as needed (docker-compose.yml, scripts, etc.)

## Customizing Templates

All templates are designed to be customized. Common customizations include:

### Adding VS Code Extensions

```json
{
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-vscode.vscode-typescript-next",
        "esbenp.prettier-vscode"
      ]
    }
  }
}
```

### Setting Environment Variables

```json
{
  "containerEnv": {
    "NODE_ENV": "development",
    "DEBUG": "true"
  }
}
```

### Adding Features

```json
{
  "features": {
    "ghcr.io/devcontainers/features/node:1": {
      "version": "lts"
    }
  }
}
```

### Running Commands

```json
{
  "postCreateCommand": "npm install",
  "postAttachCommand": "echo 'Ready to code!'"
}
```

## Creating Your Own Templates

To create a custom template:

1. Create a new directory under `templates/`
2. Add a `devcontainer.json` file
3. Add a `README.md` with documentation
4. Include any additional files needed

### Template Best Practices

1. **Keep it Simple**: Start with minimal configuration
2. **Document Everything**: Explain what the template includes and why
3. **Use Comments**: Add comments in JSON files to explain options
4. **Test Thoroughly**: Ensure the template works on different systems
5. **Version Control**: Track changes to templates

## Contributing Templates

We welcome contributions! To add a new template:

1. Fork this repository
2. Create your template in `templates/your-template-name/`
3. Include comprehensive documentation
4. Test on multiple platforms
5. Submit a pull request

## Template Categories

Templates are organized by use case:

- **Minimal**: Bare minimum configurations
- **Language-Specific**: Optimized for specific programming languages
- **Framework-Specific**: Configured for specific frameworks
- **Full-Stack**: Complete development environments
- **Specialized**: Domain-specific configurations

## Resources

- [DevContainer Specification](https://containers.dev/)
- [VS Code Dev Containers Documentation](https://code.visualstudio.com/docs/devcontainers/containers)
- [DevContainer Features](https://containers.dev/features)
- [Image Documentation](../images/)