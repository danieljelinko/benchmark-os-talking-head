#!/bin/bash
set -euo pipefail

# ==========================================
# Audio2Head Setup Script
# ==========================================
# Sets up Audio2Head solution: clones repo, creates UV venv,
# installs dependencies. Model weights require manual download.
#
# Usage: bash solutions/audio2head/setup.sh

PYTHON_VERSION="3.8"
REPO_URL="https://github.com/wangsuzhen/Audio2Head.git"

echo "================================================"
echo "Setting up Audio2Head"
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
    echo "Cloning Audio2Head repository..."
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

# Create checkpoints directory
mkdir -p checkpoints

echo ""
echo "================================================"
echo "Audio2Head setup complete!"
echo "================================================"
echo ""
echo "Virtual environment: $VENV_PATH"
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
