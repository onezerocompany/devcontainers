# Playwright

Installs Playwright and all browser dependencies for end-to-end testing in development containers using mise and the npm backend.

## Dependencies

This feature requires the `mise-en-place` feature to be installed first, as it uses mise to manage Node.js and npm.

## Example Usage

```json
"features": {
    "ghcr.io/onezerocompany/features/mise-en-place:2": {},
    "ghcr.io/onezerocompany/features/playwright:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Playwright version to install (e.g., '1.40.0', 'latest') | string | latest |
| browsers | Space-separated list of browsers to install (chromium, firefox, webkit) | string | chromium firefox webkit |
| install_deps | Install system dependencies for browsers | boolean | true |

## Environment Variables

The following environment variables are set:

- `PLAYWRIGHT_BROWSERS_PATH`: Path where Playwright browsers are installed (`/ms-playwright`)
- `PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD`: Set to `0` to allow browser downloads
## Usage Examples

### Basic Installation

```json
"features": {
    "ghcr.io/onezerocompany/features/mise-en-place:2": {},
    "ghcr.io/onezerocompany/features/playwright:1": {}
}
```

### Specific Browser Selection

```json
"features": {
    "ghcr.io/onezerocompany/features/mise-en-place:2": {},
    "ghcr.io/onezerocompany/features/playwright:1": {
        "browsers": "chromium webkit"
    }
}
```

### Specific Playwright Version

```json
"features": {
    "ghcr.io/onezerocompany/features/mise-en-place:2": {},
    "ghcr.io/onezerocompany/features/playwright:1": {
        "version": "1.40.0",
        "browsers": "chromium firefox webkit"
    }
}
```

### No System Dependencies (Framework Only)

```json
"features": {
    "ghcr.io/onezerocompany/features/mise-en-place:2": {},
    "ghcr.io/onezerocompany/features/playwright:1": {
        "install_deps": false,
        "browsers": ""
    }
}
```

## Usage

After installation, you can use Playwright in your project:

```bash
# Run Playwright commands via mise
mise exec -- npx playwright test

# Or if you have a local installation
npm install --save-dev @playwright/test
npx playwright test
```

## Container Compatibility

This feature is designed for containerized environments and automatically installs all necessary system dependencies for running browsers in headless mode. The browsers run without sandbox by default for container compatibility.