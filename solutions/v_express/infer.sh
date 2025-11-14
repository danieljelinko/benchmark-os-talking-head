#!/bin/bash
set -euo pipefail

# ==========================================
# V-Express Inference Script
# ==========================================
# Runs V-Express inference with standardized interface.
#
# Usage: bash solutions/v_express/infer.sh --image <path> [--audio <path>] [--text "<text>"] [--tts <coqui|piper>]
#
# Args:
#   --image: Path to input image (required)
#   --audio: Path to input audio file (optional if --text provided)
#   --text: Text to synthesize (optional if --audio provided)
#   --tts: TTS backend to use: coqui or piper (default: coqui)

# Get directories
SOLUTION_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$SOLUTION_DIR/repo"
REPO_ROOT="$(dirname "$(dirname "$SOLUTION_DIR")")"
VENV_PATH="$SOLUTION_DIR/.venv"

# Check if venv exists
if [ ! -d "$VENV_PATH" ]; then
    echo "ERROR: Virtual environment not found at: $VENV_PATH"
    echo "Please run: bash solutions/v_express/setup.sh"
    exit 1
fi

# Activate virtual environment
source "$VENV_PATH/bin/activate"

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
    TEMP_AUDIO="/tmp/v_express_tts_$(date +%s).wav"

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
OUTPUT_DIR="$REPO_ROOT/outputs/v_express"
mkdir -p "$OUTPUT_DIR"

# Define output path
OUTPUT_FILE="$OUTPUT_DIR/result_$(date +%s).mp4"

# Change to repo directory
cd "$REPO_DIR"

# Run V-Express inference
echo ""
echo "================================================"
echo "Running V-Express inference..."
echo "================================================"
echo "Image: $IMAGE"
echo "Audio: $AUDIO"
echo "Output: $OUTPUT_FILE"
echo ""

# Note: The exact command may vary based on V-Express's inference script
# Check the repo's README for the correct inference command and parameters
if [ -f "inference.py" ]; then
    # Adjust parameters based on actual V-Express API
    python inference.py \
        --reference_image "$IMAGE" \
        --audio_path "$AUDIO" \
        --output_path "$OUTPUT_FILE"
elif [ -f "run_inference.py" ]; then
    python run_inference.py \
        --image "$IMAGE" \
        --audio "$AUDIO" \
        --output "$OUTPUT_FILE"
else
    echo "ERROR: Could not find inference script (inference.py or run_inference.py)"
    echo "Please check the V-Express repository structure and update this script"
    exit 1
fi

echo ""
echo "================================================"
echo "V-Express inference complete!"
echo "================================================"
echo "Output file: $OUTPUT_FILE"
echo ""
ls -lh "$OUTPUT_FILE" 2>/dev/null || echo "Note: Check repository output directories for results"
echo ""
