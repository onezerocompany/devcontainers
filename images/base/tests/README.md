# Base Image Tests

This directory contains comprehensive tests for the devcontainer base images, including tests for s6-overlay functionality.

## Test Files

### `test.sh`
Main test script that runs during Docker build in CI. Tests:
- User setup and permissions
- Mise installation and tools
- Shell configurations
- Entrypoint functionality
- Docker availability (if applicable)
- Common utilities
- Environment variables
- Package installations
- S6-overlay installation and configuration

### `test-s6-overlay.sh`
Static tests for s6-overlay that run during build time. Tests:
- S6-overlay installation (binaries, directories)
- Service definitions (type files, scripts)
- Log pipeline configuration
- Bundle structure
- Service dependencies
- Log management setup

### `test-s6-runtime.sh`
Runtime tests for s6-overlay services. These tests require a running container with s6-overlay active. Tests:
- S6-svscan process
- Docker service startup
- Service dependency resolution
- Docker socket permissions
- Service stability
- Log collection

## CI Integration

In CI (GitHub Actions), tests run during the Docker build process:

1. **Build-time tests** (`test.sh` and `test-s6-overlay.sh`) run as part of the `test-standard` and `test-dind` build targets
2. These tests verify the image is correctly built and configured
3. Only static checks are performed - no runtime services are tested in CI

## Local Testing

For comprehensive testing including runtime behavior:

```bash
# Run all tests including build and runtime
./run-tests.sh

# Test specific variant with docker-compose
docker-compose -f docker-compose.test.yml up test-dind

# Run runtime tests in an interactive container
docker run --rm -it --privileged <image> /tests/test-s6-runtime.sh

# Debug s6-overlay services
docker-compose -f docker-compose.test.yml up debug-dind
```

## Test Coverage

### Standard Variant
- Basic functionality without Docker
- S6-overlay is installed but not used for services
- No Docker daemon or related services

### DIND Variant
- All standard variant tests
- Docker daemon managed by s6-overlay
- Log collection via s6-log
- Service dependencies (dockerd → docker-permissions)
- Docker socket permission management

## Troubleshooting

If tests fail in CI:
1. Check the build logs for specific test failures
2. Run tests locally to reproduce
3. Use the debug containers to investigate

Common issues:
- **S6 service files**: Ensure all service files are executable
- **Dependencies**: Check that dependency files exist and are empty
- **Permissions**: Verify file ownership and permissions
- **Multi-platform**: Test both amd64 and arm64 locally if possible