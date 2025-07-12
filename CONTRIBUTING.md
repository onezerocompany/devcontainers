# Contributing to OneZero DevContainers

Thank you for your interest in contributing to OneZero DevContainers! This document provides guidelines and instructions for contributing to this project.

## Code of Conduct

By participating in this project, you agree to maintain a respectful and inclusive environment for all contributors.

## How to Contribute

### Reporting Issues

1. Check if the issue already exists in the [issue tracker](https://github.com/onezerocompany/devcontainers/issues)
2. If not, create a new issue with:
   - Clear title and description
   - Steps to reproduce (for bugs)
   - Expected vs actual behavior
   - Environment details (OS, Docker version, etc.)

### Submitting Pull Requests

1. Fork the repository
2. Create a feature branch from `main`
3. Make your changes
4. Test your changes thoroughly
5. Commit with clear, descriptive messages
6. Push to your fork
7. Submit a pull request to `main`

### Development Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/onezerocompany/devcontainers.git
   cd devcontainers
   ```

2. Install development dependencies:
   - Docker and Docker Compose
   - VS Code with Remote-Containers extension
   - mise (for testing features)

### Project Structure

- `/features/src/` - DevContainer feature definitions
- `/features/test/` - Feature tests
- `/images/` - Docker image definitions
- `/devcontainers/` - Pre-configured devcontainer setups
- `/.github/workflows/` - CI/CD pipelines

## Development Guidelines

### Features

When creating or modifying features:

1. Follow the [DevContainer Features specification](https://containers.dev/implementors/features/)
2. Include comprehensive `devcontainer-feature.json`
3. Write clear installation scripts (`install.sh`)
4. Add a detailed README.md
5. Include tests in `/features/test/[feature-name]/`

### Docker Images

When working with Docker images:

1. Use multi-platform builds (amd64 and arm64 when possible)
2. Minimize image layers
3. Follow Docker best practices
4. Pin base image versions
5. Include clear documentation

### Testing

#### Feature Testing

```bash
cd features/test/[feature-name]
./test.sh
```

#### Local Image Building

```bash
# Build base image
docker build -t base ./images/base

# Build dependent images
docker build -t dind ./images/dind
docker build -t devcontainer:base ./images/devcontainer:base
docker build -t devcontainer:dind ./images/devcontainer:dind
docker build -t runner ./images/runner
```

### Commit Messages

Follow conventional commits format:
- `feat:` New features
- `fix:` Bug fixes
- `docs:` Documentation changes
- `test:` Test additions/modifications
- `refactor:` Code refactoring
- `chore:` Maintenance tasks

### Versioning

- Features use semantic versioning (major.minor.patch)
- Update version in `devcontainer-feature.json`
- Document changes in CHANGELOG.md

## Release Process

1. Features and images are automatically published when merged to `main`
2. CI/CD runs daily builds at 3 AM UTC
3. All artifacts are published to GitHub Container Registry

## Getting Help

- Open an issue for questions
- Check existing documentation
- Review closed issues and PRs for similar topics

## License

By contributing, you agree that your contributions will be licensed under the MIT License.