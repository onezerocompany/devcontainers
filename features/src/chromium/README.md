# Chromium

Installs Chromium browser and dependencies for headless browser testing in development containers.

## Example Usage

```json
"features": {
    "ghcr.io/onezerocompany/features/chromium:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| install_puppeteer_deps | Install additional dependencies required for Puppeteer | boolean | true |
| install_playwright_deps | Install additional dependencies required for Playwright | boolean | false |
| install_chromedriver | Install ChromeDriver for Selenium testing | boolean | false |
| chrome_flags | Default Chrome flags for container environments | string | --no-sandbox --disable-setuid-sandbox --disable-dev-shm-usage |
| set_environment_vars | Set CHROME_BIN and CHROMIUM_FLAGS environment variables | boolean | true |

## Environment Variables

When `set_environment_vars` is enabled (default), the following environment variables are set:

- `CHROME_BIN`: Path to the Chromium binary
- `CHROMIUM_FLAGS`: Default flags for running Chromium in containers

## Usage Examples

### Basic Installation

```json
"features": {
    "ghcr.io/onezerocompany/features/chromium:1": {}
}
```

### With Puppeteer Support

```json
"features": {
    "ghcr.io/onezerocompany/features/chromium:1": {
        "install_puppeteer_deps": true
    }
}
```

### With Playwright Support

```json
"features": {
    "ghcr.io/onezerocompany/features/chromium:1": {
        "install_playwright_deps": true
    }
}
```

### With Selenium/ChromeDriver

```json
"features": {
    "ghcr.io/onezerocompany/features/chromium:1": {
        "install_chromedriver": true
    }
}
```

### Custom Chrome Flags

```json
"features": {
    "ghcr.io/onezerocompany/features/chromium:1": {
        "chrome_flags": "--headless --disable-gpu --no-sandbox"
    }
}
```

## Test Wrapper

The feature includes a test wrapper script at `/usr/local/bin/chromium-test` that automatically applies the container-friendly flags when running Chromium.

```bash
# Run Chromium with default container flags
chromium-test https://example.com

# Run headless
chromium-test --headless --dump-dom https://example.com
```

## Container Compatibility

This feature is designed to work in containerized environments where Chromium typically needs special flags to run properly:

- `--no-sandbox`: Disables the sandbox for all process types that are normally sandboxed
- `--disable-setuid-sandbox`: Disables the setuid sandbox
- `--disable-dev-shm-usage`: Disables the use of /dev/shm for shared memory

These flags are automatically set in the `CHROMIUM_FLAGS` environment variable and used by the `chromium-test` wrapper.