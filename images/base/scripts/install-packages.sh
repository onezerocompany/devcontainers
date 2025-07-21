#!/bin/bash
# Main package installation orchestrator for devcontainer base image
# This script simply calls all the installation scripts in order
set -e

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Run all installation scripts in order
"${SCRIPT_DIR}/system/system-prep.sh"
"${SCRIPT_DIR}/system/apt-fast.sh"

# Export APT_CMD for subsequent scripts
export APT_CMD="apt-fast"

"${SCRIPT_DIR}/system/system-upgrade.sh"
"${SCRIPT_DIR}/tools/core-utilities.sh"
"${SCRIPT_DIR}/development/build-tools.sh"
"${SCRIPT_DIR}/development/dev-tools.sh"
"${SCRIPT_DIR}/tools/container-tools.sh"
"${SCRIPT_DIR}/tools/modern-cli.sh"
"${SCRIPT_DIR}/system/cleanup.sh"

echo "✅ Package installation complete!"