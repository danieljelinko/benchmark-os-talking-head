#!/bin/bash
set -euo pipefail

# ==========================================
# EchoMimic Setup Script
# ==========================================
# Sets up EchoMimic solution: clones repo, creates UV venv,
# installs dependencies, and downloads model weights.
#
# Usage: bash solutions/echomimic/setup.sh

PYTHON_VERSION="3.8"
REPO_URL="https://github.com/antgroup/echomimic.git"
WEIGHTS_REPO="https://huggingface.co/BadToBest/EchoMimic"

echo "================================================"
echo "Setting up EchoMimic"
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
    echo "Cloning EchoMimic repository..."
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

# Change to repo directory
cd "$REPO_DIR"

# Install requirements
if [ -f requirements.txt ]; then
    echo "Installing requirements from requirements.txt..."
    uv pip install -r requirements.txt
else
    echo "WARNING: requirements.txt not found, skipping..."
fi

# Initialize git-lfs for downloading large model files
echo "Initializing git-lfs..."
git lfs install

# Download pretrained weights from Hugging Face
if [ -d "pretrained_weights" ]; then
    echo "Pretrained weights directory already exists"
else
    echo "Downloading pretrained weights from Hugging Face..."
    echo "This may take a while (large model files)..."
    git clone "$WEIGHTS_REPO" pretrained_weights
fi

echo ""
echo "================================================"
echo "EchoMimic setup complete!"
echo "================================================"
echo ""
echo "Virtual environment: $VENV_PATH"
echo "Repository: $REPO_DIR"
echo ""
echo "To run inference:"
echo "  bash solutions/echomimic/infer.sh --image <path> --text \"Hello world\""
echo ""
