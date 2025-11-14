#!/bin/bash
set -euo pipefail

# ==========================================
# Coqui TTS Setup Script
# ==========================================
# Sets up Coqui TTS in a dedicated UV virtual environment.
#
# Usage: bash tts/setup_coqui.sh

PYTHON_VERSION="3.10"

echo "================================================"
echo "Setting up Coqui TTS"
echo "================================================"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VENV_DIR="$SCRIPT_DIR/coqui_env"
VENV_PATH="$VENV_DIR/.venv"

# Check if UV is available
if ! command -v uv &> /dev/null; then
    echo "ERROR: UV is not installed."
    echo "Please run: bash bootstrap/install_system_deps.sh"
    exit 1
fi

# Create venv directory
mkdir -p "$VENV_DIR"

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

# Upgrade pip (UV installs latest by default, but let's be explicit)
echo "Ensuring pip is up to date..."
uv pip install --upgrade pip

# Install Coqui TTS
echo "Installing Coqui TTS..."
uv pip install TTS

echo ""
echo "================================================"
echo "Coqui TTS installed successfully!"
echo "================================================"
echo ""
echo "Virtual environment: $VENV_PATH"
echo ""
echo "To test the installation, activate the environment and run:"
echo "  source $VENV_PATH/bin/activate"
echo "  tts --list_models"
echo "  deactivate"
echo ""
echo "To generate speech from text:"
echo "  bash tts/say_coqui.sh \"Hello world\" /tmp/test.wav"
echo ""
