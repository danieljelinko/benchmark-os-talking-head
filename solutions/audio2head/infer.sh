#!/bin/bash
set -euo pipefail

# ==========================================
# Audio2Head Inference Script
# ==========================================
# Runs Audio2Head inference with standardized interface.
#
# Usage: bash solutions/audio2head/infer.sh --image <path> [--audio <path>] [--text "<text>"] [--tts <coqui|piper>]
#
# Args:
#   --image: Path to input image (required, should be square-cropped)
#   --audio: Path to input audio file (optional if --text provided)
#   --text: Text to synthesize (optional if --audio provided)
#   --tts: TTS backend to use: coqui or piper (default: coqui)
#
# IMPORTANT: Audio2Head requires a square-cropped face image!

# Source conda
if [ -f "$HOME/miniconda/etc/profile.d/conda.sh" ]; then
    source "$HOME/miniconda/etc/profile.d/conda.sh"
elif [ -f "$HOME/anaconda3/etc/profile.d/conda.sh" ]; then
    source "$HOME/anaconda3/etc/profile.d/conda.sh"
else
    echo "ERROR: Could not find conda.sh"
    exit 1
fi

# Activate environment
conda activate audio2head

# Get directories
SOLUTION_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$SOLUTION_DIR/repo"
REPO_ROOT="$(dirname "$(dirname "$SOLUTION_DIR")")"

# Initialize argument variables
IMAGE=""
AUDIO=""
TEXT=""
TTS_BACKEND="coqui"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --image)
            IMAGE="$2"
            shift 2
            ;;
        --audio)
            AUDIO="$2"
            shift 2
            ;;
        --text)
            TEXT="$2"
            shift 2
            ;;
        --tts)
            TTS_BACKEND="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Validate image is provided
if [ -z "$IMAGE" ]; then
    echo "ERROR: --image is required"
    echo "Usage: $0 --image <path> [--audio <path>] [--text \"<text>\"] [--tts <coqui|piper>]"
    exit 1
fi

if [ ! -f "$IMAGE" ]; then
    echo "ERROR: Image file not found: $IMAGE"
    exit 1
fi

echo "NOTE: Audio2Head works best with square-cropped face images."
echo "If your image is not square-cropped, results may be suboptimal."
echo ""

# Generate audio from text if needed
if [ -n "$TEXT" ] && [ -z "$AUDIO" ]; then
    echo "Generating audio from text using $TTS_BACKEND..."
    TEMP_AUDIO="/tmp/audio2head_tts_$(date +%s).wav"

    if [ "$TTS_BACKEND" = "piper" ]; then
        bash "$REPO_ROOT/tts/say_piper.sh" "$TEXT" "$TEMP_AUDIO"
    else
        bash "$REPO_ROOT/tts/say_coqui.sh" "$TEXT" "$TEMP_AUDIO"
    fi

    AUDIO="$TEMP_AUDIO"
fi

# Validate audio is available
if [ -z "$AUDIO" ]; then
    echo "ERROR: Either --audio or --text must be provided"
    exit 1
fi

if [ ! -f "$AUDIO" ]; then
    echo "ERROR: Audio file not found: $AUDIO"
    exit 1
fi

# Change to repo directory
cd "$REPO_DIR"

# Run Audio2Head inference
echo ""
echo "================================================"
echo "Running Audio2Head inference..."
echo "================================================"
echo "Image: $IMAGE"
echo "Audio: $AUDIO"
echo ""

# Note: The exact command may vary based on Audio2Head's inference script
# Check the repo's README for the correct inference command and parameters
if [ -f "inference.py" ]; then
    python inference.py \
        --audio_path "$AUDIO" \
        --img_path "$IMAGE"
elif [ -f "demo.py" ]; then
    python demo.py \
        --audio "$AUDIO" \
        --image "$IMAGE"
else
    echo "ERROR: Could not find inference script (inference.py or demo.py)"
    echo "Please check the Audio2Head repository structure and update this script"
    exit 1
fi

echo ""
echo "================================================"
echo "Audio2Head inference complete!"
echo "================================================"
echo ""
echo "NOTE: Output location depends on Audio2Head's configuration."
echo "Check the repository's output directories:"
echo "  $REPO_DIR/outputs/"
echo "  $REPO_DIR/results/"
echo ""
