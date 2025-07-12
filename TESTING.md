# Testing Guide

This repository includes comprehensive tests for all integrated features.

## Test Structure

### CI/CD Tests

1. **Image Build Tests** (`publish.yml`)
   - Builds all images in the correct dependency order
   - Publishes to GitHub Container Registry
   - Tests basic devcontainer startup

2. **Comprehensive Feature Tests** (`test-images.yml`)
   - **Sandbox Integration Tests**
     - Verifies sandbox is disabled by default
     - Tests runtime enable/disable functionality
     - Confirms immutability once enabled
     - Validates firewall functionality
   
   - **Docker Integration Tests**
     - Checks Docker CLI installation
     - Verifies Docker Compose (v1 and v2)
     - Tests Docker Buildx
     - Validates socket access and permissions
   
   - **Base Image Tests**
     - VS Code extensions
     - Common utilities (fzf, bat, eza, starship, zoxide)
     - Tools command functionality
   
   - **Real-World Scenarios**
     - Development workflow with sandbox
     - Docker build/run operations
     - Container persistence

3. **Security Tests** (`test-sandbox-security.yml`)
   - **Attack Vector Tests**
     - State file tampering protection
     - Environment variable injection
     - Process manipulation attempts
     - File system attacks
   
   - **Edge Case Tests**
     - Rapid enable/disable cycles
     - Concurrent access
     - Empty/special environment variables
     - Performance impact

## Running Tests Locally

### Quick Test Script

```bash
# Run all basic tests locally
./test-local.sh
```

This script runs essential tests without needing GitHub Actions.

### Manual Testing

#### Test Sandbox Integration

```bash
# Test sandbox can be enabled
docker run --rm \
  -e DEVCONTAINER_SANDBOX_ENABLED=true \
  -e DEVCONTAINER_SANDBOX_FIREWALL=true \
  -e DEVCONTAINER=true \
  --cap-add NET_ADMIN \
  ghcr.io/onezerocompany/devcontainer:base \
  bash -c '/usr/local/bin/devcontainer-entrypoint curl -s https://api.github.com'

# Test immutability
docker run --rm \
  -e DEVCONTAINER_SANDBOX_ENABLED=true \
  -e DEVCONTAINER=true \
  --cap-add NET_ADMIN \
  ghcr.io/onezerocompany/devcontainer:base \
  bash -c '
    /usr/local/bin/devcontainer-entrypoint true
    export DEVCONTAINER_SANDBOX_ENABLED=false
    /usr/local/bin/devcontainer-entrypoint echo "Should still be sandboxed"
  '
```

#### Test Docker Integration

```bash
# Test Docker functionality
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker-host.sock \
  ghcr.io/onezerocompany/devcontainer:dind \
  bash -c '
    /usr/local/share/docker-init.sh
    docker run hello-world
  '
```

## Test Coverage

### Sandbox Feature
- ✅ Default state (disabled)
- ✅ Runtime enablement
- ✅ Immutability after enable
- ✅ Firewall functionality
- ✅ State file protection
- ✅ Environment variable injection protection
- ✅ Process manipulation protection
- ✅ Concurrent access handling
- ✅ Performance impact

### Docker Feature
- ✅ CLI installation
- ✅ Docker Compose v1/v2
- ✅ Docker Buildx
- ✅ Socket forwarding
- ✅ User permissions
- ✅ Container operations

### Base Image
- ✅ VS Code extensions
- ✅ Development utilities
- ✅ Shell configuration
- ✅ User environment

## Adding New Tests

1. **For new features**: Add tests to `test-images.yml`
2. **For security concerns**: Add tests to `test-sandbox-security.yml`
3. **For local development**: Update `test-local.sh`

## Debugging Failed Tests

1. **Check logs**: Use `gh run view <run-id> --log`
2. **Run locally**: Use the commands from the workflow files
3. **Interactive debugging**:
   ```bash
   # Start a container for debugging
   docker run -it --rm \
     -e DEVCONTAINER_SANDBOX_ENABLED=true \
     -e DEVCONTAINER=true \
     --cap-add NET_ADMIN \
     ghcr.io/onezerocompany/devcontainer:base \
     bash
   ```

## Performance Benchmarks

The sandbox feature adds minimal overhead:
- Startup: < 100ms additional
- Runtime: No measurable impact
- Memory: < 1MB additional