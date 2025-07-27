#!/bin/bash
# Chromium Installation Script

set -e

export DEBIAN_FRONTEND=noninteractive

# Enable error handling
set -o pipefail

# Feature options
INSTALL_PUPPETEER_DEPS="${INSTALL_PUPPETEER_DEPS:-true}"
INSTALL_PLAYWRIGHT_DEPS="${INSTALL_PLAYWRIGHT_DEPS:-false}"
INSTALL_CHROMEDRIVER="${INSTALL_CHROMEDRIVER:-false}"
CHROME_FLAGS="${CHROME_FLAGS:---no-sandbox --disable-setuid-sandbox --disable-dev-shm-usage}"
SET_ENVIRONMENT_VARS="${SET_ENVIRONMENT_VARS:-true}"

# Get system architecture
ARCH=$(dpkg --print-architecture)

echo "Installing Chromium for testing..."
echo "Architecture: $ARCH"
echo "Options: puppeteer_deps=$INSTALL_PUPPETEER_DEPS, playwright_deps=$INSTALL_PLAYWRIGHT_DEPS, chromedriver=$INSTALL_CHROMEDRIVER"

# Update package list
apt-get update

# Install Chromium and basic dependencies
echo "Installing Chromium browser..."
apt-get install -y \
    chromium \
    chromium-driver \
    fonts-liberation \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libc6 \
    libcairo2 \
    libcups2 \
    libdbus-1-3 \
    libexpat1 \
    libfontconfig1 \
    libgbm1 \
    libgcc1 \
    libglib2.0-0 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libpango-1.0-0 \
    libpangocairo-1.0-0 \
    libstdc++6 \
    libx11-6 \
    libx11-xcb1 \
    libxcb1 \
    libxcomposite1 \
    libxcursor1 \
    libxdamage1 \
    libxext6 \
    libxfixes3 \
    libxi6 \
    libxrandr2 \
    libxrender1 \
    libxss1 \
    libxtst6 \
    lsb-release \
    wget \
    xdg-utils

# Install additional Puppeteer dependencies if requested
if [ "$INSTALL_PUPPETEER_DEPS" = "true" ]; then
    echo "Installing additional Puppeteer dependencies..."
    apt-get install -y \
        ca-certificates \
        fonts-noto-color-emoji \
        libxkbcommon0 \
        libgbm-dev
fi

# Install additional Playwright dependencies if requested
if [ "$INSTALL_PLAYWRIGHT_DEPS" = "true" ]; then
    echo "Installing additional Playwright dependencies..."
    apt-get install -y \
        libgstreamer-gl1.0-0 \
        libgstreamer-plugins-bad1.0-0 \
        libwoff1 \
        libvpx7 \
        libwebpdemux2 \
        libenchant-2-2 \
        libsecret-1-0 \
        libhyphen0 \
        libmanette-0.2-0 \
        libgles2
fi

# Install ChromeDriver separately if it wasn't included with chromium
if [ "$INSTALL_CHROMEDRIVER" = "true" ] && ! command -v chromedriver &> /dev/null; then
    echo "Installing ChromeDriver..."
    apt-get install -y chromium-driver || {
        # Fallback: Download ChromeDriver manually if package not available
        echo "Package chromium-driver not found, downloading manually..."
        CHROME_VERSION=$(chromium --version | awk '{print $2}' | cut -d. -f1)
        CHROMEDRIVER_VERSION=$(curl -s "https://chromedriver.storage.googleapis.com/LATEST_RELEASE_$CHROME_VERSION")
        
        if [ "$ARCH" = "amd64" ]; then
            CHROMEDRIVER_ARCH="linux64"
        elif [ "$ARCH" = "arm64" ]; then
            CHROMEDRIVER_ARCH="linux64"  # ChromeDriver uses same binary for arm64
        else
            echo "Unsupported architecture for ChromeDriver: $ARCH"
            exit 1
        fi
        
        wget -q "https://chromedriver.storage.googleapis.com/$CHROMEDRIVER_VERSION/chromedriver_$CHROMEDRIVER_ARCH.zip" -O /tmp/chromedriver.zip
        unzip -o /tmp/chromedriver.zip -d /usr/local/bin/
        chmod +x /usr/local/bin/chromedriver
        rm /tmp/chromedriver.zip
    }
fi

# Set up environment variables if requested
if [ "$SET_ENVIRONMENT_VARS" = "true" ]; then
    echo "Setting up environment variables..."
    
    # Find the Chromium binary path
    CHROME_BIN=$(which chromium || which chromium-browser || echo "/usr/bin/chromium")
    
    # Add to /etc/environment for system-wide access
    {
        echo "CHROME_BIN=$CHROME_BIN"
        echo "CHROMIUM_FLAGS=\"$CHROME_FLAGS\""
    } >> /etc/environment
    
    # Also add to profile.d for shell sessions
    cat > /etc/profile.d/chromium-testing.sh << EOF
export CHROME_BIN="$CHROME_BIN"
export CHROMIUM_FLAGS="$CHROME_FLAGS"
EOF
    
    chmod +x /etc/profile.d/chromium-testing.sh
fi

# Create a wrapper script for Chromium with default flags
cat > /usr/local/bin/chromium-test << 'EOF'
#!/bin/bash
# Wrapper script for running Chromium with testing-friendly flags

CHROME_BIN="${CHROME_BIN:-$(which chromium || which chromium-browser || echo "/usr/bin/chromium")}"
CHROMIUM_FLAGS="${CHROMIUM_FLAGS:---no-sandbox --disable-setuid-sandbox --disable-dev-shm-usage}"

exec "$CHROME_BIN" $CHROMIUM_FLAGS "$@"
EOF

chmod +x /usr/local/bin/chromium-test

# Verify installation
echo "Verifying Chromium installation..."
if chromium --version || chromium-browser --version; then
    echo "✓ Chromium installed successfully"
else
    echo "✗ Chromium installation verification failed"
    exit 1
fi

if [ "$INSTALL_CHROMEDRIVER" = "true" ]; then
    if chromedriver --version; then
        echo "✓ ChromeDriver installed successfully"
    else
        echo "✗ ChromeDriver installation verification failed"
    fi
fi

# Clean up
apt-get autoremove -y
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "Chromium testing environment setup complete!"
echo "Chromium binary: $(which chromium || which chromium-browser || echo "not found")"
echo "Test wrapper: /usr/local/bin/chromium-test"
if [ "$INSTALL_CHROMEDRIVER" = "true" ]; then
    echo "ChromeDriver: $(which chromedriver || echo "not found")"
fi

# Ensure we exit with success
exit 0