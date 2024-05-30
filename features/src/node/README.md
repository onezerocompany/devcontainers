# Node.js (node)

Node.js and NPM

## Example Usage

```json
"features": {
    "ghcr.io/onezerocompany/devcontainers/features/node:1": {}
}
```

## Options

| Options Id      | Description                                  | Type    | Default Value |
| --------------- | -------------------------------------------- | ------- | ------------- |
| install         | Install Node.js                              | boolean | true          |
| yarn            | Install Yarn package manager                 | boolean | true          |
| pnpm            | Install PNPM package manager                 | boolean | true          |
| version         | Node.js version                              | string  | lts           |
| global_packages | Global packages to install (comma separated) | string  | -             |
| user            | User to run the container as                 | string  | zero          |

---

_Note: This file was auto-generated from the [devcontainer-feature.json](devcontainer-feature.json). Add additional notes to a `NOTES.md`._
