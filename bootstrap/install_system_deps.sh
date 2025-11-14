#!/bin/bash
set -euo pipefail

# ==========================================
# System Dependencies Installation Script
# ==========================================
# This script installs all required system packages and dependencies
# for the talking head benchmarking framework.
#
# Usage: bash bootstrap/install_system_deps.sh

echo "================================================"
echo "Installing System Dependencies"
echo "================================================"

# Update package list
echo "Updating package list..."
sudo apt-get update

# Install core packages
echo "Installing core packages..."
sudo apt-get install -y \
    git \
    git-lfs \
    ffmpeg \
    build-essential \
    curl \
    wget \
    python3-dev \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1

# Initialize git-lfs
echo "Initializing git-lfs..."
git lfs install

echo ""
echo "================================================"
echo "System packages installed successfully!"
echo "================================================"
echo ""

# Call UV setup script
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
echo "Installing UV (Python package manager)..."
bash "$SCRIPT_DIR/make_uv.sh"

echo ""
echo "================================================"
echo "Bootstrap complete!"
echo "================================================"
echo ""
echo "IMPORTANT: UV has been added to your PATH."
echo "For new shells, restart or run:"
echo "  source ~/.bashrc"
echo ""
echo "Verify UV is available:"
echo "  uv --version"
echo ""
