# OneZero Unified Devcontainer

A comprehensive development container that uses [mise](https://mise.jdx.dev/) for managing programming languages and development tools.

## Features

This devcontainer includes:

- **mise** - Polyglot runtime manager for all your development tools
- **common-utils** - Essential shell utilities (zoxide, eza, bat, starship, etc.)

## Default Tools

The container comes pre-configured with the following tools via mise:

- Node.js (LTS)
- Python 3.12
- Bun (latest)
- GitHub CLI
- kubectl
- Helm
- Google Cloud CLI
- Firebase CLI
- Trivy (container security scanner)
- 1Password CLI

## Customization

### Adding More Tools

You can customize the tools available in your project by creating a `.mise.toml` file in your project root:

```toml
[tools]
node = "20.11.0"      # Specific version
python = "3.11"       # Different Python version
go = "latest"         # Add Go
rust = "stable"       # Add Rust
ruby = "3.3"          # Add Ruby
```

### Available Tools via mise

mise supports hundreds of tools. Some popular ones include:

- **Languages**: go, rust, ruby, java, dotnet, php, elixir, erlang, swift
- **JavaScript**: deno, yarn, pnpm
- **Cloud Tools**: aws-cli, azure-cli, gcloud
- **Databases**: postgresql, mysql, redis, mongodb
- **Others**: docker-compose, k9s, poetry, pipenv, cargo-make

Run `mise plugins list` to see all available tools.

## Usage

1. Open your project in VS Code
2. When prompted, reopen in the devcontainer
3. mise will automatically install the tools defined in `.mise.toml`
4. Start developing!

## VS Code Extensions

The following extensions are pre-installed:

- EditorConfig
- GitLens
- GitHub Pull Requests
- Docker
- Makefile Tools

## Tips

- Use `mise list` to see installed tools
- Use `mise install <tool>` to add new tools
- Use `mise use <tool>@<version>` to set a specific version
- Create project-specific `.mise.toml` files to ensure consistent environments