#!/bin/bash
# System preparation and package repository setup
set -e

echo "🔧 Preparing system..."

# Update package lists
apt-get update -y

# Install package management prerequisites
# Note: curl and wget are already provided by buildpack-deps
apt-get install -y software-properties-common