# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- PR validation workflow for automated testing
- Security scanning with Trivy in CI/CD pipeline
- CONTRIBUTING.md with contribution guidelines
- LICENSE file (MIT)
- README.md for firebase and github-cli features
- .dockerignore files for all Docker images
- Versioning strategy documentation
- This CHANGELOG.md file

### Changed
- Base image now supports configurable username via build args
- Removed hardcoded credentials from base Dockerfile

### Removed
- References to non-existent devcontainers (flutter, astro, minimal, containers)
- Migration guide reference that didn't exist

### Security
- Fixed hardcoded user credentials in base image
- Added security scanning to PR validation

## [2.0.0] - 2024-01-10

### Changed
- Migrated to mise for tool management
- Replaced Oh My Posh with Starship
- Upgraded common-utils to version 2.0.0

## [1.0.0] - Initial Release

### Added
- Base Docker images (base, dind, devcontainer-base, runner, firebase-toolkit)
- DevContainer features:
  - common-utils: Essential shell utilities
  - docker: Docker-in-Docker support
  - kubernetes: Kubernetes development tools
  - flutter: Flutter SDK support
  - mise: Polyglot runtime manager
  - firebase: Firebase CLI
  - github-cli: GitHub CLI
  - claude-code: Claude Code CLI integration
- Automated publishing workflow
- Basic test infrastructure