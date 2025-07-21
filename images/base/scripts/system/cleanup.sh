#!/bin/bash
# Cleanup to reduce image size
set -e

echo "🧹 Cleaning up..."

# Remove package lists to reduce image size
apt-get clean
rm -rf /var/lib/apt/lists/*