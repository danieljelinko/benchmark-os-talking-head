#!/bin/bash
set -euo pipefail

# ==========================================
# Wav2Lip Setup Script
# ==========================================
# Sets up Wav2Lip solution: clones repo, creates conda env,
# installs dependencies, and downloads model weights.
#
# Usage: bash solutions/wav2lip/setup.sh

ENV_NAME="wav2lip"
PYTHON_VERSION="3.8"
REPO_URL="https://github.com/Rudrabha/Wav2Lip.git"

echo "================================================"
echo "Setting up Wav2Lip"
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
    echo "Cloning Wav2Lip repository..."
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
echo "Environment: $ENV_NAME"
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
