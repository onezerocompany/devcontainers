# mise (mise)

mise - dev tools, env vars, task runner

## Example Usage

```json
"features": {
    "ghcr.io/onezerocompany/devcontainers/features/mise:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| install | Install mise | boolean | true |
| version | mise version | string | latest |
| user | User to run mise as | string | zero |
| autoTrustWorkspace | Automatically trust mise config files in /workspaces/* (opt-in for security) | boolean | false |
| trustedPaths | Additional paths to auto-trust (comma-separated) | string |  |

## Security Considerations

The `autoTrustWorkspace` option allows mise to automatically trust configuration files in the `/workspaces` directory. This is disabled by default for security reasons, as mise configuration files can contain:
- Environment variables
- Shell commands via templates
- Path-based plugin versions

Only enable `autoTrustWorkspace` if you trust all projects that will be opened in your devcontainer.

## Additional Trusted Paths

You can specify additional paths to auto-trust using the `trustedPaths` option. Separate multiple paths with commas:

```json
"features": {
    "ghcr.io/onezerocompany/devcontainers/features/mise:1": {
        "trustedPaths": "/home/user/trusted-projects,/opt/company-tools"
    }
}
```

---

_Note: This file was auto-generated from the [devcontainer-feature.json](devcontainer-feature.json).  Add additional notes to a `NOTES.md`._