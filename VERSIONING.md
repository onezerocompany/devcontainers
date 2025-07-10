# Versioning Strategy

This document outlines the versioning strategy for the OneZero DevContainers project.

## Semantic Versioning

All components in this repository follow [Semantic Versioning](https://semver.org/):

```
MAJOR.MINOR.PATCH
```

- **MAJOR**: Incompatible API changes or breaking changes
- **MINOR**: New functionality in a backwards compatible manner
- **PATCH**: Backwards compatible bug fixes

## Component Versioning

### DevContainer Features

Each feature maintains its own version in `devcontainer-feature.json`:

```json
{
  "id": "feature-name",
  "version": "1.2.3"
}
```

#### Version Bump Guidelines:

- **MAJOR**: Breaking changes to options, removal of features, incompatible changes
- **MINOR**: New options, new functionality, new tool versions (non-breaking)
- **PATCH**: Bug fixes, documentation updates, minor tool updates

### Docker Images

Docker images are tagged with:
- `latest` - Always points to the most recent stable version
- `MAJOR` - Points to the latest version within that major version (e.g., `1`)
- `MAJOR.MINOR` - Points to the latest patch within that minor version (e.g., `1.2`)
- `MAJOR.MINOR.PATCH` - Specific version (e.g., `1.2.3`)

## Release Process

1. **Feature Changes**:
   - Update version in `devcontainer-feature.json`
   - Update CHANGELOG.md with changes
   - Create PR with changes

2. **Image Changes**:
   - Update Dockerfile if needed
   - Update CHANGELOG.md with changes
   - Tag release after merge

3. **Automated Publishing**:
   - Features and images are automatically published on merge to main
   - Daily builds ensure latest security updates

## Version Dependencies

When features depend on specific image versions:
- Document minimum required versions in README
- Use version constraints in feature definitions
- Test compatibility before releasing

## Deprecation Policy

- Deprecated features/options marked in documentation
- Deprecation warnings added to install scripts
- Minimum 3 months before removal
- Major version bump on removal

## Changelog Format

See CHANGELOG.md for the standard format used for documenting changes.