# OneZero Common Utils (common-utils)

Common utilities for OneZero projects

## Example Usage

```json
"features": {
    "ghcr.io/onezerocompany/devcontainers/features/common-utils:1": {}
}
```

## Options

| Options Id | Description                                                           | Type    | Default Value |
| ---------- | --------------------------------------------------------------------- | ------- | ------------- |
| auto_cd    | Automatically change to the project directory when opening a terminal | boolean | true          |
| zoxide     | Install Zoxide for fast directory navigation                          | boolean | true          |
| eza        | Install Eza for easy project management                               | boolean | true          |
| bat        | Install Bat for syntax highlighting                                   | boolean | true          |
| motd       | Install a message of the day for the terminal                         | boolean | true          |
| user       | User to run the container as                                          | string  | zero          |

---

_Note: This file was auto-generated from the [devcontainer-feature.json](devcontainer-feature.json). Add additional notes to a `NOTES.md`._
