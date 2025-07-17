# Settings Generator Image

A utility container image for generating DevContainer settings and configurations, built on Alpine Linux with Node.js and the DevContainers CLI.

## Overview

This image provides a lightweight utility for:
- Generating DevContainer configurations
- Validating DevContainer settings
- Processing DevContainer templates
- CLI-based DevContainer operations

## Architecture

```
settings-gen:latest
    └── docker:dind (Alpine Linux)
        └── Node.js 20
        └── @devcontainers/cli
```

## Features

### DevContainer CLI
- **@devcontainers/cli**: Official DevContainers CLI tool
- **Template Processing**: Generate configurations from templates
- **Validation**: Validate DevContainer configurations
- **Feature Management**: Install and configure DevContainer features

### Utilities
- **Node.js 20**: Latest stable Node.js runtime
- **jq**: JSON processor for configuration manipulation
- **Docker-in-Docker**: Full Docker support for container operations

### Generation Script
- **gen.sh**: Custom generation script for configuration processing
- **Flexible Input**: Supports various input formats and sources
- **Automated Processing**: Batch processing capabilities

## Usage

### Basic Generation

```bash
# Generate basic DevContainer configuration
docker run --rm \
  -v $(pwd):/workspace \
  ghcr.io/onezerocompany/settings-gen:latest \
  generate --template basic
```

### With Custom Template

```bash
# Generate from custom template
docker run --rm \
  -v $(pwd):/workspace \
  -v /path/to/templates:/templates \
  ghcr.io/onezerocompany/settings-gen:latest \
  generate --template /templates/custom.json
```

### Validation

```bash
# Validate DevContainer configuration
docker run --rm \
  -v $(pwd):/workspace \
  ghcr.io/onezerocompany/settings-gen:latest \
  validate --config /workspace/.devcontainer/devcontainer.json
```

### DevContainer CLI Commands

#### Building Containers

```bash
# Build DevContainer
docker run --rm \
  -v $(pwd):/workspace \
  -v /var/run/docker.sock:/var/run/docker.sock \
  ghcr.io/onezerocompany/settings-gen:latest \
  build --workspace-folder /workspace
```

#### Feature Installation

```bash
# Install DevContainer features
docker run --rm \
  -v $(pwd):/workspace \
  ghcr.io/onezerocompany/settings-gen:latest \
  features install --features "node:lts,python:3.11"
```

#### Template Operations

```bash
# List available templates
docker run --rm \
  ghcr.io/onezerocompany/settings-gen:latest \
  templates list

# Apply template
docker run --rm \
  -v $(pwd):/workspace \
  ghcr.io/onezerocompany/settings-gen:latest \
  templates apply --template node
```

## Configuration Examples

### Basic DevContainer Generation

```bash
# Generate minimal configuration
docker run --rm \
  -v $(pwd):/workspace \
  ghcr.io/onezerocompany/settings-gen:latest \
  gen.sh --type basic --output /workspace/.devcontainer
```

### Advanced Configuration

```bash
# Generate with features and customizations
docker run --rm \
  -v $(pwd):/workspace \
  -e FEATURES="node:lts,python:3.11,docker-in-docker" \
  -e EXTENSIONS="ms-python.python,ms-vscode.vscode-typescript-next" \
  ghcr.io/onezerocompany/settings-gen:latest \
  gen.sh --type advanced --output /workspace/.devcontainer
```

### Batch Processing

```bash
# Process multiple projects
docker run --rm \
  -v /path/to/projects:/projects \
  -v /path/to/templates:/templates \
  ghcr.io/onezerocompany/settings-gen:latest \
  gen.sh --batch --input /projects --template /templates/standard.json
```

## Environment Variables

| Variable | Default | Description | Example |
|----------|---------|-------------|---------|
| `WORKSPACE_DIR` | `/workspace` | Workspace directory | `/app` |
| `TEMPLATE_DIR` | `/templates` | Template directory | `/custom-templates` |
| `OUTPUT_DIR` | `.devcontainer` | Output directory | `devcontainer-config` |
| `FEATURES` | - | Comma-separated features | `node:lts,python:3.11` |
| `EXTENSIONS` | - | VS Code extensions | `ms-python.python` |
| `BASE_IMAGE` | `ubuntu:22.04` | Base container image | `node:18-alpine` |

## Volume Mounts

| Container Path | Description | Recommended Host Mount |
|----------------|-------------|------------------------|
| `/workspace` | Project workspace | Project root directory |
| `/templates` | Template directory | Custom template folder |
| `/output` | Output directory | Configuration output folder |
| `/var/run/docker.sock` | Docker socket | `/var/run/docker.sock` |

## DevContainer Templates

### Basic Template

```json
{
  "name": "Basic Development Environment",
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "customizations": {
    "vscode": {
      "settings": {
        "terminal.integrated.shell.linux": "/bin/bash"
      }
    }
  }
}
```

### Node.js Template

```json
{
  "name": "Node.js Development",
  "image": "mcr.microsoft.com/devcontainers/javascript-node:lts",
  "features": {
    "ghcr.io/devcontainers/features/node:1": {
      "version": "lts"
    }
  },
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-vscode.vscode-typescript-next",
        "esbenp.prettier-vscode"
      ]
    }
  },
  "postCreateCommand": "npm install"
}
```

### Python Template

```json
{
  "name": "Python Development",
  "image": "mcr.microsoft.com/devcontainers/python:3.11",
  "features": {
    "ghcr.io/devcontainers/features/python:1": {
      "version": "3.11"
    }
  },
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-python.python",
        "ms-python.pylint"
      ]
    }
  },
  "postCreateCommand": "pip install -r requirements.txt"
}
```

## Generation Script (gen.sh)

### Basic Usage

```bash
# Generate basic configuration
gen.sh --type basic --name "My Project" --output /workspace/.devcontainer

# Generate with features
gen.sh --type advanced --features "node:lts,python:3.11" --output /workspace/.devcontainer

# Generate from template
gen.sh --template /templates/custom.json --output /workspace/.devcontainer
```

### Script Options

| Option | Description | Example |
|--------|-------------|---------|
| `--type` | Configuration type | `basic`, `advanced`, `minimal` |
| `--name` | Container name | `"My Development Environment"` |
| `--template` | Template file path | `/templates/node.json` |
| `--features` | DevContainer features | `"node:lts,python:3.11"` |
| `--extensions` | VS Code extensions | `"ms-python.python"` |
| `--output` | Output directory | `/workspace/.devcontainer` |
| `--batch` | Batch processing mode | Flag |
| `--validate` | Validate configuration | Flag |

## CLI Commands

### DevContainers CLI

```bash
# Build container
devcontainer build --workspace-folder /workspace

# Up container
devcontainer up --workspace-folder /workspace

# Execute command
devcontainer exec --workspace-folder /workspace -- npm install

# Features
devcontainer features install --features "node:lts"
devcontainer features list

# Templates
devcontainer templates list
devcontainer templates apply --template node --workspace-folder /workspace
```

### JSON Processing

```bash
# Process configuration with jq
jq '.customizations.vscode.extensions += ["ms-python.python"]' devcontainer.json

# Merge configurations
jq -s '.[0] * .[1]' base.json custom.json > merged.json

# Extract features
jq '.features' devcontainer.json
```

## Docker Compose Usage

```yaml
version: '3.8'

services:
  settings-gen:
    image: ghcr.io/onezerocompany/settings-gen:latest
    volumes:
      - ./projects:/workspace
      - ./templates:/templates
      - ./output:/output
    environment:
      - FEATURES=node:lts,python:3.11
      - EXTENSIONS=ms-python.python,ms-vscode.vscode-typescript-next
    command: gen.sh --type advanced --output /output
```

## Automation Examples

### CI/CD Pipeline

```yaml
name: Generate DevContainer Config

on:
  push:
    paths:
      - '.devcontainer-template/**'

jobs:
  generate:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Generate DevContainer Configuration
      run: |
        docker run --rm \
          -v ${{ github.workspace }}:/workspace \
          ghcr.io/onezerocompany/settings-gen:latest \
          gen.sh --template /workspace/.devcontainer-template/template.json \
                 --output /workspace/.devcontainer
    
    - name: Commit generated configuration
      run: |
        git config --local user.email "action@github.com"
        git config --local user.name "GitHub Action"
        git add .devcontainer/
        git commit -m "Update DevContainer configuration" || exit 0
        git push
```

### Batch Processing

```bash
#!/bin/bash
# Process multiple projects

PROJECTS_DIR="/path/to/projects"
TEMPLATE_FILE="/path/to/templates/standard.json"

for project in "$PROJECTS_DIR"/*; do
    if [ -d "$project" ]; then
        echo "Processing $project..."
        docker run --rm \
            -v "$project":/workspace \
            -v "$(dirname "$TEMPLATE_FILE")":/templates \
            ghcr.io/onezerocompany/settings-gen:latest \
            gen.sh --template /templates/$(basename "$TEMPLATE_FILE") \
                   --output /workspace/.devcontainer
    fi
done
```

## Troubleshooting

### Common Issues

1. **Permission Errors**
   ```bash
   # Fix volume permissions
   sudo chown -R $USER:$USER /path/to/workspace
   ```

2. **Docker Socket Access**
   ```bash
   # Fix Docker socket permissions
   sudo chmod 666 /var/run/docker.sock
   ```

3. **Template Not Found**
   ```bash
   # Check template path
   docker run --rm \
     -v $(pwd):/workspace \
     ghcr.io/onezerocompany/settings-gen:latest \
     ls -la /templates
   ```

### Debugging

```bash
# Debug mode
docker run --rm -it \
  -v $(pwd):/workspace \
  ghcr.io/onezerocompany/settings-gen:latest \
  sh

# Check DevContainer CLI version
docker run --rm \
  ghcr.io/onezerocompany/settings-gen:latest \
  devcontainer --version

# Validate configuration
docker run --rm \
  -v $(pwd):/workspace \
  ghcr.io/onezerocompany/settings-gen:latest \
  jq . /workspace/.devcontainer/devcontainer.json
```

## Best Practices

1. **Use Templates**: Create reusable templates for common configurations
2. **Validate Configs**: Always validate generated configurations
3. **Version Control**: Track template changes in version control
4. **Batch Processing**: Use batch mode for multiple projects
5. **Custom Features**: Define custom features for specific needs
6. **Documentation**: Document custom templates and configurations

## Notes

- Built on Alpine Linux for minimal size
- Includes Docker-in-Docker support for container operations
- Node.js 20 provides modern JavaScript runtime
- DevContainers CLI enables full DevContainer functionality
- jq utility allows advanced JSON processing
- Custom gen.sh script provides simplified interface