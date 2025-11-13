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

# Call conda setup script
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
echo "Installing Miniconda..."
bash "$SCRIPT_DIR/make_conda.sh"

echo ""
echo "================================================"
echo "Bootstrap complete!"
echo "================================================"
echo ""
echo "IMPORTANT: Restart your shell or run:"
echo "  source ~/.bashrc"
echo ""
echo "Then verify conda is available:"
echo "  conda --version"
echo ""
