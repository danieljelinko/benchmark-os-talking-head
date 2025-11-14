#!/bin/bash
set -euo pipefail

# ==========================================
# Wav2Lip Inference Script
# ==========================================
# Runs Wav2Lip inference with standardized interface.
#
# Usage: bash solutions/wav2lip/infer.sh --image <path> [--audio <path>] [--text "<text>"] [--tts <coqui|piper>] [--checkpoint <path>]
#
# Args:
#   --image: Path to input image (required)
#   --audio: Path to input audio file (optional if --text provided)
#   --text: Text to synthesize (optional if --audio provided)
#   --tts: TTS backend to use: coqui or piper (default: coqui)
#   --checkpoint: Path to checkpoint (default: checkpoints/wav2lip_gan.pth)

# Get directories
SOLUTION_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$SOLUTION_DIR/repo"
REPO_ROOT="$(dirname "$(dirname "$SOLUTION_DIR")")"
VENV_PATH="$SOLUTION_DIR/.venv"

# Check if venv exists
if [ ! -d "$VENV_PATH" ]; then
    echo "ERROR: Virtual environment not found at: $VENV_PATH"
    echo "Please run: bash solutions/wav2lip/setup.sh"
    exit 1
fi

# Activate virtual environment
source "$VENV_PATH/bin/activate"

# Initialize argument variables
IMAGE=""
AUDIO=""
TEXT=""
TTS_BACKEND="coqui"
CHECKPOINT="checkpoints/wav2lip_gan.pth"

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
        --checkpoint)
            CHECKPOINT="$2"
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
    TEMP_AUDIO="/tmp/wav2lip_tts_$(date +%s).wav"

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

# Ensure ffmpeg is available
bash "$REPO_ROOT/common/ensure_ffmpeg.sh"

# Convert image to silent video (Wav2Lip requires video input)
echo "Converting image to video..."
TEMP_VIDEO="/tmp/wav2lip_video_$(date +%s).mp4"
# Get audio duration to match video length
AUDIO_DURATION=$(ffprobe -i "$AUDIO" -show_entries format=duration -v quiet -of csv="p=0")
bash "$REPO_ROOT/common/img_to_silent_video.sh" "$IMAGE" "$TEMP_VIDEO" "$AUDIO_DURATION" 25

# Create output directory
OUTPUT_DIR="$REPO_ROOT/outputs/wav2lip"
mkdir -p "$OUTPUT_DIR"

# Define output path
OUTPUT_FILE="$OUTPUT_DIR/result_$(date +%s).mp4"

# Change to repo directory
cd "$REPO_DIR"

# Run Wav2Lip inference
echo ""
echo "================================================"
echo "Running Wav2Lip inference..."
echo "================================================"
echo "Image: $IMAGE"
echo "Audio: $AUDIO"
echo "Checkpoint: $CHECKPOINT"
echo "Output: $OUTPUT_FILE"
echo ""

python inference.py \
    --checkpoint_path "$CHECKPOINT" \
    --face "$TEMP_VIDEO" \
    --audio "$AUDIO" \
    --outfile "$OUTPUT_FILE"

# Clean up temporary video
rm -f "$TEMP_VIDEO"

echo ""
echo "================================================"
echo "Wav2Lip inference complete!"
echo "================================================"
echo "Output file: $OUTPUT_FILE"
echo ""
ls -lh "$OUTPUT_FILE"
echo ""
