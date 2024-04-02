
# Go (go)

Installs Go and common Go utilities. Auto-detects latest version and installs needed dependencies.

## Example Usage

```json
"features": {
    "ghcr.io/onezerocompany/devcontainers/features/go:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| install | Install Go | boolean | true |
| version | Select or enter a Go version to install | string | latest |
| golangciLintVersion | Version of golangci-lint to install | string | latest |

## Customizations

### VS Code Extensions

- `golang.Go`



---

_Note: This file was auto-generated from the [devcontainer-feature.json](devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
