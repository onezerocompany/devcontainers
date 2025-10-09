#!/bin/bash
# Install Playwright with all browsers and system dependencies for CI/CD testing

set -e

echo "Installing Playwright with multi-browser support..."

export DEBIAN_FRONTEND=noninteractive

# Update package list
apt-get update -y

# Install Node.js dependencies for Playwright system requirements
# These are common dependencies needed before installing Playwright browsers
apt-get install -y \
    libnss3 \
    libnspr4 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libdbus-1-3 \
    libxkbcommon0 \
    libatspi2.0-0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libpango-1.0-0 \
    libcairo2 \
    libasound2 \
    libxshmfence1

# Install Node.js 20 LTS (required for Playwright)
# Using official NodeSource repository for latest stable version
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

# Verify Node.js installation
echo "Node.js version: $(node --version)"
echo "npm version: $(npm --version)"

# Install Playwright package globally
# Using latest version for most up-to-date browser support
npm install -g playwright@latest

# Install all browsers with their system dependencies
# This includes: Chromium, Firefox, WebKit, and optionally Edge
echo "Installing Playwright browsers and system dependencies..."

# Install all default browsers (Chromium, Firefox, WebKit) with dependencies
playwright install --with-deps chromium firefox webkit

# Install Microsoft Edge for additional browser coverage
playwright install --with-deps msedge

# Verify installation
echo "Verifying Playwright browser installation..."
playwright install --dry-run

# Set up browser cache permissions
# Playwright browsers are stored in /root/.cache/ms-playwright by default when run as root
if [ -d "/root/.cache/ms-playwright" ]; then
    echo "Setting up browser cache permissions..."
    chmod -R 755 /root/.cache/ms-playwright
fi

# Clean up
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "Playwright installation completed successfully!"
echo "Installed browsers:"
echo "  - Chromium"
echo "  - Firefox"
echo "  - WebKit"
echo "  - Microsoft Edge"
