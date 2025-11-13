#!/bin/bash
set -euo pipefail

# ==========================================
# Image to Silent Video Converter
# ==========================================
# Converts a still image into a silent video of specified duration.
#
# Usage: bash common/img_to_silent_video.sh <image> <output> <duration> <fps>
#
# Args:
#   $1: Input image path
#   $2: Output video path
#   $3: Duration in seconds (default: 5)
#   $4: Frames per second (default: 25)

IMAGE_PATH="${1:-}"
OUTPUT_PATH="${2:-}"
DURATION="${3:-5}"
FPS="${4:-25}"

# Validate input
if [ -z "$IMAGE_PATH" ]; then
    echo "ERROR: Image path is required"
    echo "Usage: $0 <image> <output> [duration] [fps]"
    exit 1
fi

if [ -z "$OUTPUT_PATH" ]; then
    echo "ERROR: Output path is required"
    echo "Usage: $0 <image> <output> [duration] [fps]"
    exit 1
fi

if [ ! -f "$IMAGE_PATH" ]; then
    echo "ERROR: Input image does not exist: $IMAGE_PATH"
    exit 1
fi

echo "Creating silent video from image..."
echo "  Input: $IMAGE_PATH"
echo "  Output: $OUTPUT_PATH"
echo "  Duration: ${DURATION}s"
echo "  FPS: $FPS"

# Create parent directory if needed
mkdir -p "$(dirname "$OUTPUT_PATH")"

# Convert image to video using ffmpeg
# -loop 1: Loop the input (image)
# -i: Input file
# -t: Duration
# -r: Frame rate
# -c:v libx264: Use H.264 codec
# -pix_fmt yuv420p: Pixel format for compatibility
# -loglevel error: Suppress verbose output
ffmpeg -loop 1 -i "$IMAGE_PATH" -t "$DURATION" -r "$FPS" \
    -c:v libx264 -pix_fmt yuv420p \
    -loglevel error -y "$OUTPUT_PATH"

echo "Silent video created: $OUTPUT_PATH"
