#!/bin/bash
# fd (modern find) installation
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/utils.sh"

# Check if fd should be installed (individual option or shell bundle)
if ! should_install_tool "FD" "SHELLBUNDLE"; then
    echo "  ⏭️  Skipping fd installation (disabled)"
    return 0
fi

echo "  🔧 Installing fd (modern find)..."
if command -v cargo >/dev/null 2>&1; then
    cargo install fd-find
    echo "  ✅ fd installed via cargo"
elif is_debian_based; then
    apt_get_update_if_needed
    apt-get install -y fd-find
    
    # Create fd symlink if fd doesn't exist but fdfind does
    if [[ ! -e /usr/local/bin/fd ]] && [[ -e /usr/bin/fdfind ]]; then
        # Ensure /usr/local/bin exists
        mkdir -p /usr/local/bin
        ln -sf /usr/bin/fdfind /usr/local/bin/fd
        echo "  🔗 Created fd symlink: /usr/local/bin/fd -> /usr/bin/fdfind"
    fi
    
    # Also create symlink in /usr/bin if needed (fallback)
    if [[ ! -e /usr/bin/fd ]] && [[ -e /usr/bin/fdfind ]]; then
        ln -sf /usr/bin/fdfind /usr/bin/fd
        echo "  🔗 Created fd symlink: /usr/bin/fd -> /usr/bin/fdfind"
    fi
    
    # Verify installation
    if command -v fd >/dev/null 2>&1; then
        echo "  ✅ fd installed and available via apt"
    else
        echo "  ⚠️  fd package installed but command not found in PATH"
    fi
elif command -v brew >/dev/null 2>&1; then
    brew install fd
    echo "  ✅ fd installed via brew"
else
    echo "  ⚠️  No suitable package manager found for fd installation"
fi