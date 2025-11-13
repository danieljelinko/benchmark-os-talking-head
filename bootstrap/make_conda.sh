#!/bin/bash
set -euo pipefail

# ==========================================
# Miniconda Installation Script
# ==========================================
# Installs Miniconda package manager if not already installed.
#
# Usage: bash bootstrap/make_conda.sh

CONDA_DIR="$HOME/miniconda"
CONDA_INSTALLER="/tmp/miniconda_installer.sh"
MINICONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"

echo "================================================"
echo "Miniconda Installation"
echo "================================================"

# Check if conda is already installed
if command -v conda &> /dev/null; then
    echo "Conda is already installed:"
    conda --version
    echo "Skipping installation."
    exit 0
fi

# Check if miniconda directory exists
if [ -d "$CONDA_DIR" ]; then
    echo "Miniconda directory already exists at $CONDA_DIR"
    echo "Initializing conda for bash..."
    eval "$($CONDA_DIR/bin/conda shell.bash hook)"
    conda init bash
    echo "Done! Please restart your shell."
    exit 0
fi

# Download Miniconda installer
echo "Downloading Miniconda installer..."
curl -L -o "$CONDA_INSTALLER" "$MINICONDA_URL"

# Install Miniconda
echo "Installing Miniconda to $CONDA_DIR..."
bash "$CONDA_INSTALLER" -b -p "$CONDA_DIR"

# Clean up installer
rm -f "$CONDA_INSTALLER"

# Initialize conda for bash
echo "Initializing conda for bash shell..."
eval "$($CONDA_DIR/bin/conda shell.bash hook)"
conda init bash

echo ""
echo "================================================"
echo "Miniconda installed successfully!"
echo "================================================"
echo ""
echo "IMPORTANT: Please restart your shell or run:"
echo "  source ~/.bashrc"
echo ""
echo "Then verify conda is available:"
echo "  conda --version"
echo ""
