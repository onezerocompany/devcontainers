# Sandbox Integration in Base DevContainer

The sandbox functionality is now built into the base devcontainer image but is **disabled by default**. It can be enabled at container runtime through environment variables that cannot be modified from inside the container.

## Security Design

1. **Truly Immutable Configuration**: 
   - Sandbox settings are read from environment variables only on first container start
   - Settings are stored in root-owned, read-only state files in `/var/lib/devcontainer-sandbox/`
   - Changing environment variables after container start has no effect
   
2. **Protected Scripts**: 
   - The entrypoint wrapper and firewall scripts are owned by root
   - State files are chmod 400 (read-only) and owned by root
   - Even with sudo access, users cannot modify these files
   
3. **Runtime Control**: 
   - The sandbox can be enabled/disabled without rebuilding the image
   - Once the container starts, the sandbox state is locked

## Configuration

Use these environment variables in your `devcontainer.json`:

```json
{
  "containerEnv": {
    "DEVCONTAINER_SANDBOX_ENABLED": "true",        // Enable sandbox features
    "DEVCONTAINER_SANDBOX_FIREWALL": "true",       // Enable network firewall
    "DEVCONTAINER_SANDBOX_ALLOWED_DOMAINS": "..."  // Comma-separated additional domains
  },
  "capAdd": ["NET_ADMIN"]  // Required for firewall functionality
}
```

## Environment Variables

- `DEVCONTAINER_SANDBOX_ENABLED`: Set to "true" to enable sandbox mode
- `DEVCONTAINER_SANDBOX_FIREWALL`: Set to "true" to enable firewall restrictions
- `DEVCONTAINER_SANDBOX_ALLOWED_DOMAINS`: Comma-separated list of additional domains to allow

## Default Allowed Domains

When the firewall is enabled, these domains are allowed by default:
- Anthropic/Claude APIs
- GitHub and related services
- Major package managers (npm, pip, cargo, etc.)
- Linear.app
- Local/private IP ranges

## Security Notes

- Environment variables are only read on the first run when the container starts
- Once initialized, the sandbox state is stored in `/var/lib/devcontainer-sandbox/` as root-owned, read-only files
- Changing environment variables after container start has no effect on sandbox state
- The entrypoint wrapper script is immutable and owned by root
- The firewall initialization script requires sudo privileges (configured via sudoers)
- Even with sudo access, the container user cannot:
  - Disable the sandbox once enabled
  - Modify the state files (chmod 400, owned by root)
  - Change the entrypoint wrapper

## How It Works

1. When the container first starts, the entrypoint wrapper reads the `DEVCONTAINER_SANDBOX_*` environment variables
2. It creates state files in `/var/lib/devcontainer-sandbox/` with the configuration
3. These files are made read-only (chmod 400) and owned by root
4. On subsequent runs, the wrapper ignores environment variables and reads from the state files
5. This ensures the sandbox configuration is truly immutable from inside the container