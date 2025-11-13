#!/bin/bash
set -euo pipefail

# ==========================================
# SadTalker Setup Script
# ==========================================
# Sets up SadTalker solution: clones repo, creates conda env,
# installs dependencies, and downloads model weights.
#
# Usage: bash solutions/sadtalker/setup.sh

ENV_NAME="sadtalker"
PYTHON_VERSION="3.8"
REPO_URL="https://github.com/OpenTalker/SadTalker.git"

echo "================================================"
echo "Setting up SadTalker"
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
    echo "Cloning SadTalker repository..."
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

# Install PyTorch 1.12.1 with CUDA 11.3
echo "Installing PyTorch 1.12.1 with CUDA 11.3..."
pip install torch==1.12.1+cu113 torchvision==0.13.1+cu113 torchaudio==0.12.1 \
    --extra-index-url https://download.pytorch.org/whl/cu113

# Install ffmpeg via conda
echo "Installing ffmpeg via conda..."
conda install -y ffmpeg

# Install requirements
if [ -f requirements.txt ]; then
    echo "Installing requirements from requirements.txt..."
    pip install -r requirements.txt
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
echo "Environment: $ENV_NAME"
echo "Repository: $REPO_DIR"
echo ""
echo "To run inference:"
echo "  bash solutions/sadtalker/infer.sh --image <path> --text \"Hello world\""
echo ""
