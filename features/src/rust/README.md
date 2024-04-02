
# Rust (rust)

Installs Rust, common Rust utilities, and their required dependencies

## Example Usage

```json
"features": {
    "ghcr.io/onezerocompany/devcontainers/features/rust:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| install | Install Rust | boolean | true |
| version | Select or enter a version of Rust to install. | string | latest |
| profile | Select a rustup install profile. | string | minimal |

## Customizations

### VS Code Extensions

- `vadimcn.vscode-lldb`
- `rust-lang.rust-analyzer`
- `tamasfe.even-better-toml`
- `serayuzgur.crates`



---

_Note: This file was auto-generated from the [devcontainer-feature.json](devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
