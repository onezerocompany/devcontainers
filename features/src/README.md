# Archived Features

These features have been archived because they can now be managed more effectively using [mise](https://mise.jdx.dev/).

## Why were these features archived?

1. **Simplified maintenance**: Instead of maintaining separate features for each language/runtime, we now use mise which handles version management for all tools.

2. **Better version flexibility**: mise allows users to easily switch between different versions of tools without rebuilding the devcontainer.

3. **Consistent experience**: All tools are managed through a single interface (mise) rather than different installation methods.

## Archived Features

### Programming Languages
- **node**: Use `mise use node@<version>` instead
- **python**: Use `mise use python@<version>` instead
- **ruby**: Use `mise use ruby@<version>` instead
- **go**: Use `mise use go@<version>` instead
- **rust**: Use `mise use rust@<version>` instead
- **bun**: Use `mise use bun@<version>` instead
- **dart**: Use `mise use dart@<version>` instead
- **swift**: Use `mise use swift@<version>` instead

### CLI Tools
- **terraform**: Removed from the project
- **github-cli**: Use `mise use github-cli@<version>` instead
- **gcloud**: Use `mise use gcloud@<version>` instead
- **firebase**: Use `mise use firebase@<version>` instead
- **trivy**: Use `mise use trivy@<version>` instead
- **onepassword**: Use `mise use 1password-cli@<version>` instead

## Migration Guide

If you were using any of these features, update your `.devcontainer.json`:

### Before:
```json
{
  "features": {
    "ghcr.io/onezerocompany/devcontainers/features/node:1": {},
    "ghcr.io/onezerocompany/devcontainers/features/python:1": {}
  }
}
```

### After:
```json
{
  "features": {
    "ghcr.io/onezerocompany/devcontainers/features/mise:1": {}
  },
  "postCreateCommand": "mise install"
}
```

Then add a `.mise.toml` file to your project:
```toml
[tools]
node = "lts"
python = "3.12"
```

## Note

These archived features are kept for reference but should not be used in new projects. They may be removed in a future release.