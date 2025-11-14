#!/bin/bash
set -euo pipefail

# ==========================================
# V-Express Setup Script
# ==========================================
# Sets up V-Express solution: clones repo, creates UV venv,
# installs dependencies, and downloads model weights.
#
# Usage: bash solutions/v_express/setup.sh

PYTHON_VERSION="3.10"
REPO_URL="https://github.com/tencent-ailab/V-Express.git"
WEIGHTS_REPO="https://huggingface.co/tk93/V-Express"

echo "================================================"
echo "Setting up V-Express"
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
    echo "Cloning V-Express repository..."
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

# Download model weights from Hugging Face
if [ -d "model_ckpts" ]; then
    echo "Model checkpoints directory already exists"
else
    echo "Downloading model checkpoints from Hugging Face..."
    echo "This may take a while (large model files)..."

    # Clone weights repo to temporary directory
    TEMP_WEIGHTS="/tmp/v_express_weights_$$"
    git clone "$WEIGHTS_REPO" "$TEMP_WEIGHTS"

    # Move model_ckpts to repo directory
    if [ -d "$TEMP_WEIGHTS/model_ckpts" ]; then
        mv "$TEMP_WEIGHTS/model_ckpts" .
    else
        echo "WARNING: model_ckpts not found in weights repo"
        echo "You may need to download manually from: $WEIGHTS_REPO"
    fi

    # Clean up
    rm -rf "$TEMP_WEIGHTS"
fi

echo ""
echo "================================================"
echo "V-Express setup complete!"
echo "================================================"
echo ""
echo "Virtual environment: $VENV_PATH"
echo "Repository: $REPO_DIR"
echo ""
echo "To run inference:"
echo "  bash solutions/v_express/infer.sh --image <path> --text \"Hello world\""
echo ""
