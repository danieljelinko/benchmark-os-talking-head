#!/bin/bash
set -euo pipefail

# ==========================================
# Audio2Head Setup Script
# ==========================================
# Sets up Audio2Head solution: clones repo, creates conda env,
# installs dependencies. Model weights require manual download.
#
# Usage: bash solutions/audio2head/setup.sh

ENV_NAME="audio2head"
PYTHON_VERSION="3.8"
REPO_URL="https://github.com/wangsuzhen/Audio2Head.git"

echo "================================================"
echo "Setting up Audio2Head"
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
    echo "Cloning Audio2Head repository..."
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

# Create checkpoints directory
mkdir -p checkpoints

echo ""
echo "================================================"
echo "Audio2Head setup complete!"
echo "================================================"
echo ""
echo "Environment: $ENV_NAME"
echo "Repository: $REPO_DIR"
echo ""
echo "IMPORTANT: Model checkpoints require manual download!"
echo ""
echo "1. Check the Audio2Head repository README for the Google Drive link"
echo "2. Download the checkpoint files"
echo "3. Place them in: $REPO_DIR/checkpoints/"
echo ""
echo "Typical checkpoint files needed:"
echo "  - audio2head_model.pth (or similar name)"
echo "  - Other required model files as specified in README"
echo ""
echo "After downloading checkpoints, you can run inference:"
echo "  bash solutions/audio2head/infer.sh --image <path> --text \"Hello world\""
echo ""
