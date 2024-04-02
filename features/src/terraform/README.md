
# Terraform, tflint, and TFGrunt (terraform)

Installs the Terraform CLI and optionally TFLint. Auto-detects latest version and installs needed dependencies.

## Example Usage

```json
"features": {
    "ghcr.io/onezerocompany/devcontainers/features/terraform:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| install | Install Terraform | boolean | true |
| version | Terraform version | string | latest |
| tflint | Tflint version (https://github.com/terraform-linters/tflint/releases) | string | latest |
| installTfSummarize | Install tfsummarize, a tool to summarize terraform plan output | boolean | true |
| installTerraformDocs | Install terraform-docs, a utility to generate documentation from Terraform modules | boolean | true |

## Customizations

### VS Code Extensions

- `HashiCorp.terraform`



---

_Note: This file was auto-generated from the [devcontainer-feature.json](devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
