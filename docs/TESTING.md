# Testing Documentation

This document provides a comprehensive overview of the testing setup for the DevContainers project.

## Overview

The DevContainers project employs a multi-layered testing strategy that covers functionality, security, performance, and real-world usage scenarios. The testing infrastructure is primarily built using shell scripts and GitHub Actions workflows.

## Testing Philosophy

- **Comprehensive Coverage**: Tests cover all major features, security aspects, and edge cases
- **Automated Execution**: All tests run automatically via CI/CD on every push and daily
- **Security-First**: Special emphasis on sandbox security and attack vector testing
- **Performance Monitoring**: Ensures minimal overhead from security features
- **Real-World Validation**: Tests actual development workflows

## Testing Frameworks and Tools

### 1. Shell Script Testing
- **Primary Tool**: Bash scripts with colored output
- **Test Runner**: Custom test functions with pass/fail tracking
- **Assertions**: Command exit codes and output validation
- **Docker-based**: All tests run inside Docker containers

### 2. CI/CD Infrastructure
- **Platform**: GitHub Actions
- **Trigger**: Push to main branch and daily at 3 AM
- **Matrix Testing**: Multiple scenarios tested in parallel
- **Artifact Management**: Test results and performance metrics

## Test Categories

### 1. Unit Tests
Individual feature verification:
- Docker CLI tools installation
- VS Code extensions
- Common utilities (fzf, bat, eza, starship)
- User permissions and groups

### 2. Integration Tests
Full system behavior:
- Container startup validation
- Development workflow tests
- Docker-in-Docker functionality
- Multi-container scenarios

### 3. Security Tests
Sandbox and attack prevention:
- Sandbox immutability
- Firewall rule enforcement
- State file protection
- Injection attack prevention
- File system manipulation attempts
- Privilege escalation prevention

### 4. Performance Tests
Overhead measurement:
- Startup time comparison (baseline vs sandbox)
- Performance impact thresholds (<5 seconds)
- Resource utilization monitoring

### 5. Edge Case Tests
Unusual scenarios:
- Rapid enable/disable cycles
- Concurrent access attempts
- Empty environment variables
- Special characters in configurations

## Test Files Structure

```
devcontainers/
├── test-local.sh                          # Local development testing
├── images/
│   └── test/
│       ├── devcontainer:base/
│       │   └── test-sandbox.sh           # Sandbox feature tests
│       └── devcontainer:dind/
│           └── test.sh                   # Docker-in-Docker tests
└── .github/
    └── workflows/
        └── build-test-publish.yml        # CI/CD test orchestration
```

## Local Testing

### Running Tests Locally

```bash
# Ensure images are available
docker pull ghcr.io/onezerocompany/devcontainer:base
docker pull ghcr.io/onezerocompany/devcontainer:dind

# Run all tests
./test-local.sh
```

### Test Output
- Color-coded results (green=pass, red=fail)
- Test name and status for each test
- Summary with passed/failed counts
- Exit code reflects overall success

## CI/CD Testing

### GitHub Actions Jobs

1. **test-devcontainer-startup** (lines 232-255)
   - Validates devcontainer.json configuration
   - Tests container initialization
   - Verifies command execution

2. **test-sandbox-integration** (lines 257-393)
   - Default state verification
   - Enable/disable functionality
   - Immutability enforcement
   - Firewall rule testing

3. **test-docker-integration** (lines 395-494)
   - Docker CLI availability
   - Docker Compose v2 support
   - Buildx functionality
   - Socket access and permissions

4. **test-base-image-features** (lines 496-594)
   - VS Code extensions
   - Development utilities
   - Shell configurations
   - Tool availability

5. **test-real-world-scenarios** (lines 596-713)
   - Development with sandbox
   - Docker build workflows
   - Container persistence
   - State management

6. **test-sandbox-attack-vectors** (lines 715-893)
   - State file tampering
   - Environment injection
   - Process manipulation
   - File system attacks

7. **test-sandbox-edge-cases** (lines 895-1028)
   - Rapid state changes
   - Concurrent access
   - Invalid inputs
   - Special characters

8. **test-performance** (lines 1030-1075)
   - Startup time measurement
   - Overhead calculation
   - Performance thresholds

### Test Dependencies

Tests are organized with proper dependencies:
- Image builds complete before testing
- Parallel execution where possible
- Sequential execution for dependent tests

## Writing New Tests

### Local Test Template

```bash
run_test "Test Description" \
    'docker run --rm ghcr.io/onezerocompany/devcontainer:base \
        bash -c "your test commands here"'
```

### CI Test Template

```yaml
- name: Test Something New
  run: |
    docker run --rm \
      -e ENV_VAR=value \
      ghcr.io/onezerocompany/devcontainer:latest \
      bash -c "test commands"
```

## Test Best Practices

1. **Isolation**: Each test should be independent
2. **Cleanup**: Tests should not leave artifacts
3. **Clarity**: Clear test names and failure messages
4. **Speed**: Keep individual tests fast
5. **Coverage**: Test both positive and negative cases

## Security Testing Guidelines

When testing security features:
1. Always test default (disabled) state first
2. Verify immutability cannot be bypassed
3. Test common attack vectors
4. Include edge cases and malformed inputs
5. Validate error messages don't leak information

## Performance Testing Guidelines

1. Establish baseline measurements
2. Set reasonable thresholds
3. Test under consistent conditions
4. Account for variance in measurements
5. Focus on user-perceivable impacts

## Debugging Failed Tests

### Local Debugging

```bash
# Run container interactively
docker run -it --rm \
  -e DEVCONTAINER_SANDBOX_ENABLED=true \
  ghcr.io/onezerocompany/devcontainer:base \
  bash

# Check specific components
docker run --rm ghcr.io/onezerocompany/devcontainer:base \
  bash -c "ls -la /usr/local/bin/"
```

### CI Debugging

1. Check GitHub Actions logs
2. Review test output and error messages
3. Reproduce locally with same environment
4. Add debug output if needed

## Continuous Improvement

- Monitor test execution times
- Review failed test patterns
- Add tests for new features
- Update tests for changed behavior
- Remove obsolete tests

## Test Metrics

Current test coverage includes:
- **Feature Tests**: 15+ individual features
- **Security Tests**: 10+ attack vectors
- **Performance Tests**: Startup overhead monitoring
- **Integration Tests**: 5+ real-world scenarios
- **Edge Cases**: 8+ unusual conditions

## Future Enhancements

Potential improvements to testing:
1. Code coverage metrics
2. Automated vulnerability scanning
3. Load testing for concurrent users
4. Cross-platform testing
5. Accessibility testing for VS Code extensions