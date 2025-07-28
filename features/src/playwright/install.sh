#!/bin/bash
# Playwright Installation Script

set -e

export DEBIAN_FRONTEND=noninteractive

# Enable error handling
set -o pipefail

# Feature options
VERSION="${VERSION:-latest}"
BROWSERS="${BROWSERS:-chromium firefox webkit}"
INSTALL_DEPS="${INSTALL_DEPS:-true}"
INSTALL_NODE="${INSTALL_NODE:-true}"
NODE_VERSION="${NODE_VERSION:-lts}"
INSTALL_PYTHON="${INSTALL_PYTHON:-false}"
INSTALL_JAVA="${INSTALL_JAVA:-false}"
INSTALL_DOTNET="${INSTALL_DOTNET:-false}"

echo "Installing Playwright..."
echo "Options: version=$VERSION, browsers=$BROWSERS"
echo "Language support: Node=$INSTALL_NODE, Python=$INSTALL_PYTHON, Java=$INSTALL_JAVA, .NET=$INSTALL_DOTNET"

# Get system architecture
ARCH=$(dpkg --print-architecture)

# Update package list
apt-get update

# Install basic dependencies
apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    wget \
    unzip

# Install Node.js if requested and not already present
if [ "$INSTALL_NODE" = "true" ] && ! command -v node >/dev/null 2>&1; then
    echo "Installing Node.js..."
    
    # Determine Node.js version to install
    if [ "$NODE_VERSION" = "lts" ]; then
        NODE_MAJOR="20"  # Current LTS
    elif [[ "$NODE_VERSION" =~ ^[0-9]+$ ]]; then
        NODE_MAJOR="$NODE_VERSION"
    else
        # Specific version requested, extract major version
        NODE_MAJOR=$(echo "$NODE_VERSION" | cut -d. -f1)
    fi
    
    # Install Node.js from NodeSource
    curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | bash -
    apt-get install -y nodejs
    
    # Verify installation
    echo "Node.js version: $(node --version)"
    echo "npm version: $(npm --version)"
fi

# Install Playwright for Node.js
if command -v npm >/dev/null 2>&1; then
    echo "Installing Playwright for Node.js..."
    
    # Install Playwright globally
    if [ "$VERSION" = "latest" ]; then
        npm install -g playwright
    else
        npm install -g playwright@$VERSION
    fi
    
    # Install browsers and dependencies if requested
    if [ "$INSTALL_DEPS" = "true" ]; then
        echo "Installing Playwright browsers and dependencies..."
        
        # Install only the requested browsers
        for browser in $BROWSERS; do
            echo "Installing $browser..."
            npx playwright install $browser --with-deps
        done
    fi
fi

# Install Playwright for Python if requested
if [ "$INSTALL_PYTHON" = "true" ]; then
    echo "Installing Playwright for Python..."
    
    # Ensure Python and pip are installed
    if ! command -v python3 >/dev/null 2>&1; then
        apt-get install -y python3 python3-pip
    fi
    
    # Install Playwright
    if [ "$VERSION" = "latest" ]; then
        pip3 install playwright
    else
        pip3 install playwright==$VERSION
    fi
    
    # Install browsers
    if [ "$INSTALL_DEPS" = "true" ]; then
        python3 -m playwright install
        
        # Install only requested browsers
        for browser in $BROWSERS; do
            python3 -m playwright install $browser --with-deps
        done
    fi
fi

# Install Playwright for Java if requested
if [ "$INSTALL_JAVA" = "true" ]; then
    echo "Installing Playwright for Java..."
    
    # Ensure Java is installed
    if ! command -v java >/dev/null 2>&1; then
        apt-get install -y default-jdk maven
    fi
    
    # Create a directory for Playwright Java
    mkdir -p /opt/playwright-java
    
    # Note: Java users typically add Playwright as a Maven/Gradle dependency
    # We'll just ensure the system dependencies are installed
    echo "Playwright for Java: Add playwright dependency to your pom.xml or build.gradle"
fi

# Install Playwright for .NET if requested
if [ "$INSTALL_DOTNET" = "true" ]; then
    echo "Installing Playwright for .NET..."
    
    # Install .NET if not present
    if ! command -v dotnet >/dev/null 2>&1; then
        # Install .NET SDK
        wget https://dot.net/v1/dotnet-install.sh -O dotnet-install.sh
        chmod +x dotnet-install.sh
        ./dotnet-install.sh --channel 8.0
        rm dotnet-install.sh
        
        # Add to PATH
        export PATH="$PATH:$HOME/.dotnet"
        echo 'export PATH="$PATH:$HOME/.dotnet"' >> /etc/profile.d/dotnet.sh
    fi
    
    # Install PowerShell (required for Playwright .NET installation)
    if ! command -v pwsh >/dev/null 2>&1; then
        # Install PowerShell
        apt-get install -y powershell
    fi
    
    # Note: .NET users typically add Playwright via NuGet
    echo "Playwright for .NET: Add Microsoft.Playwright package via NuGet to your project"
fi

# Set up environment variables
echo "Setting up environment variables..."

# Create profile script for Playwright
cat > /etc/profile.d/playwright.sh << 'EOF'
# Playwright environment variables
export PLAYWRIGHT_BROWSERS_PATH=/ms-playwright
export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=0

# Add Playwright to NODE_PATH if Node.js is installed
if command -v node >/dev/null 2>&1; then
    export NODE_PATH="$(npm root -g):$NODE_PATH"
fi
EOF

chmod +x /etc/profile.d/playwright.sh

# Create a helper script for running Playwright tests
cat > /usr/local/bin/playwright-test << 'EOF'
#!/bin/bash
# Helper script for running Playwright tests

# Source the Playwright environment
source /etc/profile.d/playwright.sh

# Check if running Node.js tests (default)
if [ -f "package.json" ] && command -v npm >/dev/null 2>&1; then
    echo "Running Playwright tests with Node.js..."
    npx playwright test "$@"
elif [ -f "requirements.txt" ] && command -v python3 >/dev/null 2>&1; then
    echo "Running Playwright tests with Python..."
    python3 -m pytest "$@"
elif [ -f "pom.xml" ] && command -v mvn >/dev/null 2>&1; then
    echo "Running Playwright tests with Maven..."
    mvn test "$@"
elif [ -f "build.gradle" ] && command -v gradle >/dev/null 2>&1; then
    echo "Running Playwright tests with Gradle..."
    gradle test "$@"
else
    echo "No recognized test runner found. Running with npx playwright..."
    npx playwright "$@"
fi
EOF

chmod +x /usr/local/bin/playwright-test

# Verify installation
echo "Verifying Playwright installation..."

if command -v npx >/dev/null 2>&1; then
    echo "Playwright version: $(npx playwright --version)"
    echo "Installed browsers:"
    npx playwright --version || true
fi

if [ "$INSTALL_PYTHON" = "true" ] && command -v python3 >/dev/null 2>&1; then
    echo "Playwright Python version:"
    python3 -c "import playwright; print(f'playwright {playwright.__version__}')" || echo "Python playwright module not fully configured"
fi

# Clean up
apt-get autoremove -y
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "Playwright installation complete!"
echo "Test runner: /usr/local/bin/playwright-test"
echo "Browsers installed: $BROWSERS"

# Ensure we exit with success
exit 0