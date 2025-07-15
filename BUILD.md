# Local Build Script

The `build-local.sh` script builds all Docker images in this repository with proper caching support.

## Usage

```bash
./build-local.sh [OPTIONS]
```

## Options

- `--push` - Push images to registry (default: false)
- `--registry REGISTRY` - Registry to use (default: ghcr.io)
- `--image-name NAME` - Image name (default: $GITHUB_REPOSITORY_OWNER/devcontainer or local/devcontainer)
- `--platform PLATFORMS` - Platforms to build (default: linux/amd64,linux/arm64)
- `--cache-type TYPE` - Cache type: 'local' or 'registry' (default: local)
- `--help` - Show help message

## Examples

### Build all images locally with local cache
```bash
./build-local.sh
```

### Build for single platform (faster for testing)
```bash
./build-local.sh --platform linux/amd64
```

### Build and push to registry with registry cache
```bash
./build-local.sh --push --cache-type registry
```

### Build with custom image name
```bash
./build-local.sh --image-name myuser/mydevcontainer
```

## Cache Management

The script supports two cache types:

1. **Local cache** (default): Stores build cache in `.buildx-cache/` directory
2. **Registry cache**: Uses registry-based caching (requires push permissions)

## Images Built

The script builds the following images:

1. **Base image** (`base`, `latest`)
2. **Docker-in-Docker base** (`dind`)
3. **DevContainer Standard** (`devcontainer`, `devcontainer-standard`)
4. **DevContainer DIND** (`devcontainer-dind`)
5. **GitHub Actions Runner** (`runner`)
6. **Settings Generator** (`settings-gen`)

## Requirements

- Docker with BuildKit support
- Docker Buildx plugin