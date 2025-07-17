# GitHub Actions Runner Image

A specialized container image for running GitHub Actions workflows, built on top of the base image with GitHub Actions runner capabilities and Docker support.

## Overview

This image provides a self-hosted GitHub Actions runner with:
- GitHub Actions runner (latest version)
- Docker CLI and Docker Buildx plugin
- Container hooks for Kubernetes deployments
- Security sandbox support (inherited from base)
- All development tools from the base image

## Architecture

```
runner:latest
    └── base:latest
        └── Ubuntu 22.04
```

## Features

### GitHub Actions Runner
- **Latest Runner**: Automatically fetches and installs the latest GitHub Actions runner
- **Multi-Architecture**: Supports both AMD64 and ARM64 architectures
- **Container Hooks**: Includes runner container hooks for Kubernetes deployments
- **Signal Handling**: Proper signal handling for graceful shutdown

### Docker Integration
- **Docker CLI**: Full Docker command-line interface
- **Docker Buildx**: Advanced build capabilities with multi-platform support
- **Docker Group**: Runner user is added to docker group for container access

### Security Features
- **Sandbox Support**: Can initialize security sandbox if available
- **Non-root User**: Runs as `runner` user (UID 1001) with sudo access
- **Secure Defaults**: Proper permissions and group membership

## Bill of Materials

### Base Components
- All components from the base image
- GitHub Actions runner (latest version)
- Docker CLI (v27.1.1)
- Docker Buildx plugin (v0.16.2)
- Runner container hooks (v0.6.1)

### System Users
- `runner` user (UID 1001) with sudo access
- `docker` group (GID 123) for Docker access

### Environment Variables
- `RUNNER_MANUALLY_TRAP_SIG=1` - Manual signal trapping
- `ACTIONS_RUNNER_PRINT_LOG_TO_STDOUT=1` - Log output to stdout
- `ImageOS=ubuntu22` - OS identification for Actions

## Usage

### Building the Image

```bash
# Build for current platform
docker build -t runner:latest .

# Build for specific platform
docker build --platform linux/amd64 -t runner:amd64 .
docker build --platform linux/arm64 -t runner:arm64 .

# Multi-platform build
docker buildx build --platform linux/amd64,linux/arm64 -t runner:latest .
```

### Running as Self-Hosted Runner

#### Basic Setup

```bash
# Run with GitHub token and repository
docker run -it \
  -e GITHUB_TOKEN=your_token \
  -e REPO_URL=https://github.com/owner/repo \
  -v /var/run/docker.sock:/var/run/docker.sock \
  runner:latest
```

#### With Docker-in-Docker

```bash
# Run with privileged mode for full Docker support
docker run -it --privileged \
  -e GITHUB_TOKEN=your_token \
  -e REPO_URL=https://github.com/owner/repo \
  runner:latest
```

#### With Security Sandbox

```bash
# Run with sandbox enabled
docker run -it \
  --cap-add=NET_ADMIN \
  -e GITHUB_TOKEN=your_token \
  -e REPO_URL=https://github.com/owner/repo \
  -e SANDBOX_ENABLED=true \
  -e SANDBOX_ALLOWED_DOMAINS="api.github.com,github.com" \
  runner:latest
```

### Kubernetes Deployment

#### Basic Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: github-runner
spec:
  replicas: 1
  selector:
    matchLabels:
      app: github-runner
  template:
    metadata:
      labels:
        app: github-runner
    spec:
      containers:
      - name: runner
        image: ghcr.io/onezerocompany/runner:latest
        env:
        - name: GITHUB_TOKEN
          valueFrom:
            secretKeyRef:
              name: github-secrets
              key: token
        - name: REPO_URL
          value: "https://github.com/owner/repo"
        volumeMounts:
        - name: docker-sock
          mountPath: /var/run/docker.sock
      volumes:
      - name: docker-sock
        hostPath:
          path: /var/run/docker.sock
```

#### With Security Sandbox

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: secure-github-runner
spec:
  replicas: 1
  selector:
    matchLabels:
      app: secure-github-runner
  template:
    metadata:
      labels:
        app: secure-github-runner
    spec:
      containers:
      - name: runner
        image: ghcr.io/onezerocompany/runner:latest
        securityContext:
          capabilities:
            add:
              - NET_ADMIN
        env:
        - name: GITHUB_TOKEN
          valueFrom:
            secretKeyRef:
              name: github-secrets
              key: token
        - name: REPO_URL
          value: "https://github.com/owner/repo"
        - name: SANDBOX_ENABLED
          value: "true"
        - name: SANDBOX_ALLOWED_DOMAINS
          value: "api.github.com,github.com,registry.npmjs.org"
```

### Docker Compose

```yaml
version: '3.8'

services:
  github-runner:
    image: ghcr.io/onezerocompany/runner:latest
    environment:
      - GITHUB_TOKEN=${GITHUB_TOKEN}
      - REPO_URL=${REPO_URL}
      - SANDBOX_ENABLED=true
      - SANDBOX_ALLOWED_DOMAINS=api.github.com,github.com
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    cap_add:
      - NET_ADMIN
    restart: unless-stopped
```

## Configuration Options

### Environment Variables

| Variable | Default | Description | Example |
|----------|---------|-------------|---------|
| `GITHUB_TOKEN` | - | GitHub PAT or registration token | `ghp_xxx` |
| `REPO_URL` | - | Repository URL | `https://github.com/owner/repo` |
| `RUNNER_NAME` | Auto-generated | Custom runner name | `my-runner` |
| `RUNNER_LABELS` | - | Additional labels | `docker,linux,x64` |
| `RUNNER_GROUP` | `default` | Runner group | `production` |
| `SANDBOX_ENABLED` | `false` | Enable security sandbox | `true` |
| `SANDBOX_ALLOWED_DOMAINS` | - | Allowed domains | `api.github.com,npm.org` |

### Build Arguments

| Argument | Default | Description |
|----------|---------|-------------|
| `RUNNER_CONTAINER_HOOKS_VERSION` | `0.6.1` | Container hooks version |
| `DOCKER_VERSION` | `27.1.1` | Docker CLI version |
| `BUILDX_VERSION` | `0.16.2` | Docker Buildx version |

### Volume Mounts

| Container Path | Description | Recommended Host Mount |
|----------------|-------------|------------------------|
| `/var/run/docker.sock` | Docker socket | `/var/run/docker.sock` |
| `/tmp` | Temporary files | `tmpfs` |
| `/home/runner/_work` | GitHub Actions workspace | Named volume |

### Required Capabilities

| Capability | Required For | Description |
|------------|--------------|-------------|
| `NET_ADMIN` | Security sandbox | Network filtering |
| `SYS_ADMIN` | Full Docker support | Container management |

## GitHub Actions Workflow Examples

### Basic CI/CD Pipeline

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: self-hosted
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: '20'
    
    - name: Install dependencies
      run: npm install
    
    - name: Run tests
      run: npm test
    
    - name: Build application
      run: npm run build

  docker-build:
    runs-on: self-hosted
    needs: test
    steps:
    - uses: actions/checkout@v4
    
    - name: Build Docker image
      run: docker build -t myapp:latest .
    
    - name: Run container tests
      run: docker run --rm myapp:latest npm test
```

### Multi-Platform Build

```yaml
name: Multi-Platform Build

on:
  push:
    tags: ['v*']

jobs:
  build:
    runs-on: self-hosted
    steps:
    - uses: actions/checkout@v4
    
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v3
    
    - name: Build and push multi-platform image
      run: |
        docker buildx build \
          --platform linux/amd64,linux/arm64 \
          --push \
          -t myregistry/myapp:${{ github.ref_name }} \
          .
```

## Security Considerations

### Sandbox Configuration

The runner supports the same security sandbox as the base image:

```bash
# Enable sandbox with specific domains
docker run -it \
  --cap-add=NET_ADMIN \
  -e SANDBOX_ENABLED=true \
  -e SANDBOX_ALLOWED_DOMAINS="api.github.com,github.com,registry.npmjs.org" \
  runner:latest
```

### Best Practices

1. **Use Secrets**: Store sensitive information in GitHub Secrets
2. **Enable Sandbox**: Use security sandbox for untrusted code
3. **Limit Network Access**: Configure allowed domains appropriately
4. **Regular Updates**: Keep runner image updated
5. **Monitor Resources**: Set resource limits in production

## Troubleshooting

### Runner Registration Issues

1. **Invalid Token**
   ```bash
   # Check token validity
   curl -H "Authorization: token $GITHUB_TOKEN" \
     https://api.github.com/user
   ```

2. **Repository Access**
   ```bash
   # Verify repository access
   curl -H "Authorization: token $GITHUB_TOKEN" \
     https://api.github.com/repos/owner/repo
   ```

### Docker Issues

1. **Docker Socket Permission**
   ```bash
   # Fix docker socket permissions
   sudo chmod 666 /var/run/docker.sock
   ```

2. **Docker Daemon Not Running**
   ```bash
   # Start Docker daemon
   sudo systemctl start docker
   ```

### Sandbox Issues

1. **Network Connectivity**
   ```bash
   # Check firewall rules
   sudo iptables -L OUTPUT -n
   
   # Test connectivity
   curl -v https://api.github.com
   ```

2. **Missing Capabilities**
   ```bash
   # Check capabilities
   capsh --print | grep NET_ADMIN
   ```

### Performance Issues

1. **Resource Limits**
   ```bash
   # Monitor resource usage
   docker stats
   ```

2. **Disk Space**
   ```bash
   # Clean up Docker images
   docker system prune -a
   ```

## Advanced Configuration

### Custom Runner Scripts

```bash
# Create custom runner configuration
cat > runner-config.sh << 'EOF'
#!/bin/bash
./config.sh \
  --url "$REPO_URL" \
  --token "$GITHUB_TOKEN" \
  --name "$RUNNER_NAME" \
  --labels "$RUNNER_LABELS" \
  --unattended \
  --replace

./run.sh
EOF

chmod +x runner-config.sh
```

### Health Checks

```yaml
# Docker Compose with health check
version: '3.8'

services:
  github-runner:
    image: ghcr.io/onezerocompany/runner:latest
    healthcheck:
      test: ["CMD", "pgrep", "-f", "Runner.Listener"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
```

### Monitoring

```bash
# Check runner status
docker exec runner-container ps aux | grep Runner.Listener

# View runner logs
docker logs runner-container

# Monitor resource usage
docker stats runner-container
```

## Notes

- The image inherits all features from the base image
- Docker socket access is required for container operations
- Security sandbox requires NET_ADMIN capability
- Runner automatically updates to the latest version on build
- Container hooks are included for Kubernetes deployments
- Proper signal handling ensures graceful shutdown