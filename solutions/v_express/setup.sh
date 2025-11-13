#!/bin/bash
set -euo pipefail

# ==========================================
# V-Express Setup Script
# ==========================================
# Sets up V-Express solution: clones repo, creates conda env,
# installs dependencies, and downloads model weights.
#
# Usage: bash solutions/v_express/setup.sh

ENV_NAME="vexpress"
PYTHON_VERSION="3.10"
REPO_URL="https://github.com/tencent-ailab/V-Express.git"
WEIGHTS_REPO="https://huggingface.co/tk93/V-Express"

echo "================================================"
echo "Setting up V-Express"
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
    echo "Cloning V-Express repository..."
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
echo "Environment: $ENV_NAME"
echo "Repository: $REPO_DIR"
echo ""
echo "To run inference:"
echo "  bash solutions/v_express/infer.sh --image <path> --text \"Hello world\""
echo ""
