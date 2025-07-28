# Playwright

Installs Playwright and all browser dependencies for end-to-end testing in development containers.

## Example Usage

```json
"features": {
    "ghcr.io/onezerocompany/features/playwright:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Playwright version to install (e.g., '1.40.0', 'latest') | string | latest |
| browsers | Space-separated list of browsers to install (chromium, firefox, webkit) | string | chromium firefox webkit |
| install_deps | Install system dependencies for browsers | boolean | true |
| install_node | Install Node.js if not already present | boolean | true |
| node_version | Node.js version to install if needed (e.g., '18', 'lts', '20.10.0') | string | lts |
| install_python | Also install Playwright for Python | boolean | false |
| install_java | Also install Playwright for Java | boolean | false |
| install_dotnet | Also install Playwright for .NET | boolean | false |

## Environment Variables

The following environment variables are set:

- `PLAYWRIGHT_BROWSERS_PATH`: Path where Playwright browsers are installed (`/ms-playwright`)
- `PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD`: Set to `0` to allow browser downloads
- `NODE_PATH`: Updated to include global npm modules when Node.js is installed

## Usage Examples

### Basic Installation (Node.js)

```json
"features": {
    "ghcr.io/onezerocompany/features/playwright:1": {}
}
```

### Specific Browser Selection

```json
"features": {
    "ghcr.io/onezerocompany/features/playwright:1": {
        "browsers": "chromium webkit"
    }
}
```

### Python Support

```json
"features": {
    "ghcr.io/onezerocompany/features/playwright:1": {
        "install_python": true,
        "browsers": "chromium firefox"
    }
}
```

### Multiple Language Support

```json
"features": {
    "ghcr.io/onezerocompany/features/playwright:1": {
        "install_python": true,
        "install_java": true,
        "browsers": "chromium"
    }
}
```

### Specific Playwright Version

```json
"features": {
    "ghcr.io/onezerocompany/features/playwright:1": {
        "version": "1.40.0",
        "browsers": "chromium firefox webkit"
    }
}
```

### No Browser Installation (Framework Only)

```json
"features": {
    "ghcr.io/onezerocompany/features/playwright:1": {
        "install_deps": false,
        "browsers": ""
    }
}
```

## Test Runner

The feature includes a smart test runner at `/usr/local/bin/playwright-test` that automatically detects your project type and runs tests accordingly:

```bash
# Automatically detects and runs tests based on your project
playwright-test

# Pass arguments to the underlying test runner
playwright-test --headed
playwright-test test/e2e/login.spec.ts
```

The test runner supports:
- **Node.js**: Runs `npx playwright test` when `package.json` is present
- **Python**: Runs `python3 -m pytest` when `requirements.txt` is present
- **Java**: Runs `mvn test` when `pom.xml` is present or `gradle test` when `build.gradle` is present
- **Fallback**: Runs `npx playwright` with provided arguments

## Language-Specific Setup

### Node.js (Default)
Playwright is installed globally via npm. You can also install it locally in your project:
```bash
npm install --save-dev @playwright/test
```

### Python
When `install_python` is enabled, Playwright is installed via pip. Use in your project:
```python
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.launch()
    # Your test code here
```

### Java
When `install_java` is enabled, system dependencies are installed. Add Playwright to your project:
```xml
<!-- Maven -->
<dependency>
  <groupId>com.microsoft.playwright</groupId>
  <artifactId>playwright</artifactId>
  <version>1.40.0</version>
</dependency>
```

### .NET
When `install_dotnet` is enabled, .NET SDK is installed. Add Playwright via NuGet:
```bash
dotnet add package Microsoft.Playwright
```

## Container Compatibility

This feature is designed for containerized environments and automatically installs all necessary system dependencies for running browsers in headless mode. The browsers run without sandbox by default for container compatibility.