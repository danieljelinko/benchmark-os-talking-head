#!/bin/bash
set -euo pipefail

# ==========================================
# Wav2Lip Setup Script
# ==========================================
# Sets up Wav2Lip solution: clones repo, creates UV venv,
# installs dependencies, and downloads model weights.
#
# Usage: bash solutions/wav2lip/setup.sh

PYTHON_VERSION="3.8"
REPO_URL="https://github.com/Rudrabha/Wav2Lip.git"

echo "================================================"
echo "Setting up Wav2Lip"
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
    echo "Cloning Wav2Lip repository..."
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

# Create directories for checkpoints
mkdir -p checkpoints
mkdir -p face_detection/detection/sfd

# Download model weights
echo ""
echo "================================================"
echo "Downloading model weights..."
echo "================================================"
echo ""
echo "NOTE: Some model files may require manual download due to"
echo "access restrictions on Google Drive and OneDrive."
echo ""

# Wav2Lip GAN checkpoint
WAV2LIP_GAN_URL="https://github.com/Rudrabha/Wav2Lip/releases/download/models/wav2lip_gan.pth"
if [ ! -f "checkpoints/wav2lip_gan.pth" ]; then
    echo "Downloading wav2lip_gan.pth..."
    curl -L -o "checkpoints/wav2lip_gan.pth" "$WAV2LIP_GAN_URL" || {
        echo "WARNING: Failed to download wav2lip_gan.pth"
        echo "Please download manually from:"
        echo "  $WAV2LIP_GAN_URL"
        echo "  Save to: $REPO_DIR/checkpoints/wav2lip_gan.pth"
    }
else
    echo "wav2lip_gan.pth already exists"
fi

# Wav2Lip (non-GAN) checkpoint
WAV2LIP_URL="https://github.com/Rudrabha/Wav2Lip/releases/download/models/wav2lip.pth"
if [ ! -f "checkpoints/wav2lip.pth" ]; then
    echo "Downloading wav2lip.pth..."
    curl -L -o "checkpoints/wav2lip.pth" "$WAV2LIP_URL" || {
        echo "WARNING: Failed to download wav2lip.pth"
        echo "Please download manually from:"
        echo "  $WAV2LIP_URL"
        echo "  Save to: $REPO_DIR/checkpoints/wav2lip.pth"
    }
else
    echo "wav2lip.pth already exists"
fi

# Face detector (s3fd)
S3FD_URL="https://www.adrianbulat.com/downloads/python-fan/s3fd-619a316812.pth"
if [ ! -f "face_detection/detection/sfd/s3fd.pth" ]; then
    echo "Downloading s3fd.pth face detector..."
    curl -L -o "face_detection/detection/sfd/s3fd.pth" "$S3FD_URL" || {
        echo "WARNING: Failed to download s3fd.pth"
        echo "Please download manually from:"
        echo "  $S3FD_URL"
        echo "  Save to: $REPO_DIR/face_detection/detection/sfd/s3fd.pth"
    }
else
    echo "s3fd.pth already exists"
fi

echo ""
echo "================================================"
echo "Wav2Lip setup complete!"
echo "================================================"
echo ""
echo "Virtual environment: $VENV_PATH"
echo "Repository: $REPO_DIR"
echo ""

# Check if all required files exist
MISSING_FILES=false
if [ ! -f "checkpoints/wav2lip_gan.pth" ]; then
    echo "MISSING: checkpoints/wav2lip_gan.pth"
    MISSING_FILES=true
fi
if [ ! -f "checkpoints/wav2lip.pth" ]; then
    echo "MISSING: checkpoints/wav2lip.pth"
    MISSING_FILES=true
fi
if [ ! -f "face_detection/detection/sfd/s3fd.pth" ]; then
    echo "MISSING: face_detection/detection/sfd/s3fd.pth"
    MISSING_FILES=true
fi

if [ "$MISSING_FILES" = true ]; then
    echo ""
    echo "WARNING: Some model files are missing."
    echo "Please download them manually from the URLs shown above."
    echo ""
fi

echo "To run inference:"
echo "  bash solutions/wav2lip/infer.sh --image <path> --text \"Hello world\""
echo ""
