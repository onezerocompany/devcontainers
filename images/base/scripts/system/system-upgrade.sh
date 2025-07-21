#!/bin/bash
# System package upgrade
set -e

APT_CMD="${APT_CMD:-apt-get}"

echo "📦 Upgrading system packages..."
$APT_CMD upgrade -y