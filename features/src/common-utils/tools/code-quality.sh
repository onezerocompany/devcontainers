#!/bin/bash
# Code quality tools installation
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/utils.sh"

echo "  🔧 Installing code quality tools..."
if command -v npm >/dev/null 2>&1; then
    npm install -g prettier eslint
fi

if command -v pip3 >/dev/null 2>&1; then
    pip3 install black flake8 mypy
fi