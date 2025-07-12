
# Docker (docker)

Re-use the host docker socket, adding the Docker CLI to a container. Feature invokes a script to enable using a forwarded Docker socket within a container to run Docker commands.

## Example Usage

```json
"features": {
    "ghcr.io/onezerocompany/devcontainers/features/docker:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| install | Install Docker CLI | boolean | true |
| version | Select or enter a Docker/Moby CLI version. (Availability can vary by OS version.) | string | latest |
| moby | Install OSS Moby build instead of Docker CE | boolean | true |
| mobyBuildxVersion | Install a specific version of moby-buildx when using Moby | string | latest |
| dockerDashComposeVersion | Compose version to use for docker-compose (v1 or v2 or none) | string | v2 |
| installDockerBuildx | Install Docker Buildx | boolean | true |

## Customizations

### VS Code Extensions

- `ms-azuretools.vscode-docker`



---

_Note: This file was auto-generated from the [devcontainer-feature.json](devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
