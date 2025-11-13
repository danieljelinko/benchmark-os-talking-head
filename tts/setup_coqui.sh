#!/bin/bash
set -euo pipefail

# ==========================================
# Coqui TTS Setup Script
# ==========================================
# Sets up Coqui TTS in a dedicated conda environment.
#
# Usage: bash tts/setup_coqui.sh

ENV_NAME="tts"
PYTHON_VERSION="3.10"

echo "================================================"
echo "Setting up Coqui TTS"
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

# Check if environment already exists
if conda env list | grep -q "^${ENV_NAME} "; then
    echo "Conda environment '$ENV_NAME' already exists."
    echo "Activating and upgrading..."
else
    echo "Creating conda environment: $ENV_NAME (Python $PYTHON_VERSION)"
    conda create -n "$ENV_NAME" python="$PYTHON_VERSION" -y
fi

# Activate environment
echo "Activating conda environment: $ENV_NAME"
conda activate "$ENV_NAME"

# Upgrade pip
echo "Upgrading pip..."
pip install --upgrade pip

# Install Coqui TTS
echo "Installing Coqui TTS..."
pip install TTS

echo ""
echo "================================================"
echo "Coqui TTS installed successfully!"
echo "================================================"
echo ""
echo "To test the installation, activate the environment and run:"
echo "  conda activate $ENV_NAME"
echo "  tts --list_models"
echo ""
echo "To generate speech from text:"
echo "  bash tts/say_coqui.sh \"Hello world\" /tmp/test.wav"
echo ""
