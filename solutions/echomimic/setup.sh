#!/bin/bash
set -euo pipefail

# ==========================================
# EchoMimic Setup Script
# ==========================================
# Sets up EchoMimic solution: clones repo, creates conda env,
# installs dependencies, and downloads model weights.
#
# Usage: bash solutions/echomimic/setup.sh

ENV_NAME="echomimic"
PYTHON_VERSION="3.8"
REPO_URL="https://github.com/antgroup/echomimic.git"
WEIGHTS_REPO="https://huggingface.co/BadToBest/EchoMimic"

echo "================================================"
echo "Setting up EchoMimic"
echo "================================================"

# Source conda
if [ -f "$HOME/miniconda/etc/profile.d/conda.sh" ]; then
    source "$HOME/miniconda/etc/profile.d/conda.sh"
elif [ -f "$HOME/anaconda3/etc/profile.d/conda.sh" ]; then
    source "$HOME/anaconda3/etc/profile.d/conda.sh"
else
    echo "ERROR: Could not find conda.sh. Is conda installed?"
    echo "Please run: bash bootstrap/install_system_deps.sh"
    exit 1
fi

# Get solution directory
SOLUTION_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$SOLUTION_DIR/repo"

# Clone repository if not exists
if [ -d "$REPO_DIR" ]; then
    echo "Repository already exists at $REPO_DIR"
else
    echo "Cloning EchoMimic repository..."
    git clone "$REPO_URL" "$REPO_DIR"
fi

cd "$REPO_DIR"

# Check if environment already exists
if conda env list | grep -q "^${ENV_NAME} "; then
    echo "Conda environment '$ENV_NAME' already exists."
else
    echo "Creating conda environment: $ENV_NAME (Python $PYTHON_VERSION)"
    conda create -n "$ENV_NAME" python="$PYTHON_VERSION" -y
fi

# Activate environment
echo "Activating conda environment: $ENV_NAME"
conda activate "$ENV_NAME"

# Install requirements
if [ -f requirements.txt ]; then
    echo "Installing requirements from requirements.txt..."
    pip install -r requirements.txt
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
echo "Environment: $ENV_NAME"
echo "Repository: $REPO_DIR"
echo ""
echo "To run inference:"
echo "  bash solutions/echomimic/infer.sh --image <path> --text \"Hello world\""
echo ""
