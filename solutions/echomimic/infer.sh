#!/bin/bash
set -euo pipefail

# ==========================================
# EchoMimic Inference Script
# ==========================================
# Runs EchoMimic inference with standardized interface.
#
# Usage: bash solutions/echomimic/infer.sh --image <path> [--audio <path>] [--text "<text>"] [--tts <coqui|piper>]
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
    echo "Please run: bash solutions/echomimic/setup.sh"
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
    TEMP_AUDIO="/tmp/echomimic_tts_$(date +%s).wav"

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

# Create temporary config file
TEMP_CONFIG="/tmp/echomimic_config_$(date +%s).yaml"
cat > "$TEMP_CONFIG" <<EOF
test_cases:
  - img_path: "$IMAGE"
    audio_path: "$AUDIO"
EOF

# Create output directory
OUTPUT_DIR="$REPO_ROOT/outputs/echomimic"
mkdir -p "$OUTPUT_DIR"

# Change to repo directory
cd "$REPO_DIR"

# Run EchoMimic inference
echo ""
echo "================================================"
echo "Running EchoMimic inference..."
echo "================================================"
echo "Image: $IMAGE"
echo "Audio: $AUDIO"
echo "Config: $TEMP_CONFIG"
echo ""

# Note: The exact command may vary based on EchoMimic's inference script
# Check the repo's README for the correct inference command
if [ -f "infer_audio2vid.py" ]; then
    python infer_audio2vid.py --config "$TEMP_CONFIG"
elif [ -f "inference.py" ]; then
    python inference.py --config "$TEMP_CONFIG"
else
    echo "ERROR: Could not find inference script (infer_audio2vid.py or inference.py)"
    echo "Please check the EchoMimic repository structure"
    exit 1
fi

# Clean up temporary config
rm -f "$TEMP_CONFIG"

echo ""
echo "================================================"
echo "EchoMimic inference complete!"
echo "================================================"
echo ""
echo "NOTE: Output location depends on EchoMimic's configuration."
echo "Check the repository's output directories:"
echo "  $REPO_DIR/outputs/"
echo "  $REPO_DIR/results/"
echo ""
echo "You may need to manually copy output files to:"
echo "  $OUTPUT_DIR"
echo ""
