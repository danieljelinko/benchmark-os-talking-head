#!/bin/bash
set -euo pipefail

# ==========================================
# SadTalker Setup Script
# ==========================================
# Sets up SadTalker solution: clones repo, creates UV venv,
# installs dependencies, and downloads model weights.
#
# Usage: bash solutions/sadtalker/setup.sh

PYTHON_VERSION="3.8"
REPO_URL="https://github.com/OpenTalker/SadTalker.git"

echo "================================================"
echo "Setting up SadTalker"
echo "================================================"

# Check if UV is available
if ! command -v uv &> /dev/null; then
    echo "ERROR: UV is not installed."
    echo "Please run: bash bootstrap/install_system_deps.sh"
    exit 1
fi

# Get solution directory
SOLUTION_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$SOLUTION_DIR/repo"
VENV_PATH="$SOLUTION_DIR/.venv"

# Clone repository if not exists
if [ -d "$REPO_DIR" ]; then
    echo "Repository already exists at $REPO_DIR"
else
    echo "Cloning SadTalker repository..."
    git clone "$REPO_URL" "$REPO_DIR"
fi

# Check if virtual environment already exists
if [ -d "$VENV_PATH" ]; then
    echo "Virtual environment already exists at: $VENV_PATH"
    echo "Skipping creation..."
else
    echo "Installing Python $PYTHON_VERSION..."
    uv python install "$PYTHON_VERSION"

    echo "Creating virtual environment..."
    uv venv --python "$PYTHON_VERSION" "$VENV_PATH"
fi

# Activate environment
echo "Activating virtual environment..."
source "$VENV_PATH/bin/activate"

# Install PyTorch 1.12.1 with CUDA 11.3
echo "Installing PyTorch 1.12.1 with CUDA 11.3..."
uv pip install torch==1.12.1+cu113 torchvision==0.13.1+cu113 torchaudio==0.12.1 \
    --extra-index-url https://download.pytorch.org/whl/cu113

# Note: FFmpeg is installed via system packages (bootstrap)
# No need to install via conda

# Change to repo directory for requirements
cd "$REPO_DIR"

# Install requirements
if [ -f requirements.txt ]; then
    echo "Installing requirements from requirements.txt..."
    uv pip install -r requirements.txt
else
    echo "WARNING: requirements.txt not found, skipping..."
fi

# Download model weights
if [ -f scripts/download_models.sh ]; then
    echo "Downloading model weights..."
    bash scripts/download_models.sh
else
    echo "WARNING: scripts/download_models.sh not found"
    echo "You may need to download models manually"
fi

echo ""
echo "================================================"
echo "SadTalker setup complete!"
echo "================================================"
echo ""
echo "Virtual environment: $VENV_PATH"
echo "Repository: $REPO_DIR"
echo ""
echo "To run inference:"
echo "  bash solutions/sadtalker/infer.sh --image <path> --text \"Hello world\""
echo ""
