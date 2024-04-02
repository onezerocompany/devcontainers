
# Python (python)

Installs the provided version of Python, as well as PIPX, and other common Python utilities.  JupyterLab is conditionally installed with the python feature. Note: May require source code compilation.

## Example Usage

```json
"features": {
    "ghcr.io/onezerocompany/devcontainers/features/python:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| install | Flag indicating whether or not to install Python. Default is 'true'. | boolean | true |
| version | Select a Python version to install. | string | os-provided |
| installTools | Flag indicating whether or not to install the tools specified via the 'toolsToInstall' option. Default is 'true'. | boolean | true |
| toolsToInstall | Comma-separated list of tools to install when 'installTools' is true. Defaults to a set of common Python tools like pylint. | string | flake8,autopep8,black,yapf,mypy,pydocstyle,pycodestyle,bandit,pipenv,virtualenv,pytest,pylint |
| optimize | Optimize Python for performance when compiled (slow) | boolean | false |
| enableShared | Enable building a shared Python library | boolean | false |
| installPath | The path where python will be installed. | string | /usr/local/python |
| installJupyterlab | Install JupyterLab, a web-based interactive development environment for notebooks | boolean | false |
| configureJupyterlabAllowOrigin | Configure JupyterLab to accept HTTP requests from the specified origin | string | - |

## Customizations

### VS Code Extensions

- `ms-python.python`
- `ms-python.vscode-pylance`



---

_Note: This file was auto-generated from the [devcontainer-feature.json](devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
