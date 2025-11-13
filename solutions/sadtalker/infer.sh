#!/bin/bash
set -euo pipefail

# ==========================================
# SadTalker Inference Script
# ==========================================
# Runs SadTalker inference with standardized interface.
#
# Usage: bash solutions/sadtalker/infer.sh --image <path> [--audio <path>] [--text "<text>"] [--tts <coqui|piper>]
#
# Args:
#   --image: Path to input image (required)
#   --audio: Path to input audio file (optional if --text provided)
#   --text: Text to synthesize (optional if --audio provided)
#   --tts: TTS backend to use: coqui or piper (default: coqui)

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
conda activate sadtalker

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

# Generate audio from text if needed
if [ -n "$TEXT" ] && [ -z "$AUDIO" ]; then
    echo "Generating audio from text using $TTS_BACKEND..."
    TEMP_AUDIO="/tmp/sadtalker_tts_$(date +%s).wav"

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

# Create output directory
OUTPUT_DIR="$REPO_ROOT/outputs/sadtalker"
mkdir -p "$OUTPUT_DIR"

# Change to repo directory
cd "$REPO_DIR"

# Run SadTalker inference
echo ""
echo "================================================"
echo "Running SadTalker inference..."
echo "================================================"
echo "Image: $IMAGE"
echo "Audio: $AUDIO"
echo "Output: $OUTPUT_DIR"
echo ""

python inference.py \
    --driven_audio "$AUDIO" \
    --source_image "$IMAGE" \
    --result_dir "$OUTPUT_DIR" \
    --preprocess full \
    --still \
    --enhancer gfpgan

echo ""
echo "================================================"
echo "SadTalker inference complete!"
echo "================================================"
echo "Output directory: $OUTPUT_DIR"
echo ""
echo "Generated files:"
ls -lh "$OUTPUT_DIR"
echo ""
