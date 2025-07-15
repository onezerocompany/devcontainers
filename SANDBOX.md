# Sandbox Support for DevContainers

This document describes the sandbox functionality now available in all devcontainer images.

## Overview

The sandbox feature provides network isolation and security controls for containers. When enabled, it can restrict network access to only approved domains and services.

## Architecture

The sandbox functionality is implemented at the base image level, ensuring all derived images inherit these capabilities:

1. **Base Image** (`images/base/`):
   - Contains the core sandbox setup script (`setup-sandbox.sh`)
   - Includes initialization script (`init-sandbox.sh`) 
   - Provides entrypoint integration for both standard and DIND variants

2. **Derived Images**:
   - **DevContainer**: Enhanced with VS Code integration while maintaining sandbox support
   - **Runner**: GitHub Actions runner with sandbox capabilities
   - **Settings-gen**: Inherits sandbox from base image

## How It Works

1. **Setup Phase** (during image build):
   - Installs required packages (ipset, iptables, etc.)
   - Creates firewall initialization script
   - Sets up sudoers permissions

2. **Runtime Phase** (container startup):
   - Checks environment variables for sandbox configuration
   - Creates immutable state files to prevent runtime tampering
   - Optionally initializes network firewall with allowed domains

## Configuration

### Environment Variables

- `DEVCONTAINER_SANDBOX_ENABLED`: Set to `true` to enable sandbox mode
- `DEVCONTAINER_SANDBOX_FIREWALL`: Set to `true` to enable network firewall
- `DEVCONTAINER_SANDBOX_ALLOWED_DOMAINS`: Comma-separated list of additional allowed domains
- `ENABLE_SANDBOX_FIREWALL`: Alternative flag to force firewall initialization

### Example Usage

```bash
# Basic sandbox without firewall
docker run -e DEVCONTAINER_SANDBOX_ENABLED=true myimage

# Sandbox with firewall (requires NET_ADMIN capability)
docker run --cap-add NET_ADMIN \
  -e DEVCONTAINER_SANDBOX_ENABLED=true \
  -e DEVCONTAINER_SANDBOX_FIREWALL=true \
  myimage

# With additional allowed domains
docker run --cap-add NET_ADMIN \
  -e DEVCONTAINER_SANDBOX_ENABLED=true \
  -e DEVCONTAINER_SANDBOX_FIREWALL=true \
  -e DEVCONTAINER_SANDBOX_ALLOWED_DOMAINS="myapi.com,cdn.mycompany.com" \
  myimage
```

## Default Allowed Domains

When firewall is enabled, the following domains are allowed by default:

- **Anthropic/Claude**: anthropic.com, claude.ai, api.anthropic.com
- **GitHub**: github.com, api.github.com, raw.githubusercontent.com, etc.
- **Package Managers**: npmjs.org, pypi.org, rubygems.org, crates.io, bun.sh, deno.land
- **Linear**: linear.app, api.linear.app
- **Local/Private Networks**: 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16, 127.0.0.0/8

## Security Features

1. **Immutable State**: Once initialized, sandbox state cannot be changed from within the container
2. **Root-owned Configuration**: State files are owned by root and read-only
3. **Capability Checks**: Firewall only initializes if NET_ADMIN capability is available
4. **DNS Resolution**: Automatically resolves and updates IP addresses for allowed domains

## Testing

Run the test script to verify sandbox functionality:

```bash
./test-sandbox.sh
```

This will build and test all images with various sandbox configurations.

## Troubleshooting

1. **Firewall not initializing**: Ensure the container has `NET_ADMIN` capability
2. **Cannot reach allowed domain**: Check DNS resolution and that the domain is in the allowed list
3. **Sandbox not enabling**: Verify environment variables are set before container starts

## Implementation Details

The sandbox implementation consists of:

1. `setup-sandbox.sh`: Installs packages and creates firewall scripts
2. `init-sandbox.sh`: Runtime initialization called by entrypoints
3. `init-firewall.sh`: Configures iptables rules and ipsets
4. Modified entrypoints in all images to call sandbox initialization

All images now have consistent sandbox support while maintaining their specific functionality.