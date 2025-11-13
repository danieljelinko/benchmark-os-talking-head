#!/bin/bash
set -euo pipefail

# ==========================================
# Piper TTS Speech Generation Script
# ==========================================
# Generates speech from text using Piper TTS.
#
# Usage: bash tts/say_piper.sh <text> [output_path]
#
# Args:
#   text: Text to synthesize (required)
#   output_path: Path to save WAV file (optional, default: /tmp/tts_output.wav)
#
# Environment Variables:
#   PIPER_VOICE: Path to voice model (default: ~/.cache/piper/en_US-lessac-medium.onnx)

TEXT="${1:-}"
OUTPUT_PATH="${2:-/tmp/tts_output.wav}"
PIPER_VOICE="${PIPER_VOICE:-$HOME/.cache/piper/en_US-lessac-medium.onnx}"
PIPER_BIN="${HOME}/.local/bin/piper"

# Validate input
if [ -z "$TEXT" ]; then
    echo "ERROR: Text is required"
    echo "Usage: $0 <text> [output_path]"
    exit 1
fi

# Check if Piper binary exists
if [ ! -f "$PIPER_BIN" ]; then
    echo "ERROR: Piper binary not found at $PIPER_BIN"
    echo "Please run: bash tts/setup_piper.sh"
    exit 1
fi

# Check if voice model exists
if [ ! -f "$PIPER_VOICE" ]; then
    echo "ERROR: Voice model not found at $PIPER_VOICE"
    echo "Please run: bash tts/setup_piper.sh"
    exit 1
fi

# Create output directory if needed
mkdir -p "$(dirname "$OUTPUT_PATH")"

# Generate speech
echo "Generating speech with Piper TTS..."
echo "  Text: ${TEXT:0:50}${TEXT:50:+...}"
echo "  Voice: $PIPER_VOICE"
echo "  Output: $OUTPUT_PATH"

echo "$TEXT" | "$PIPER_BIN" --model "$PIPER_VOICE" --output_file "$OUTPUT_PATH"

echo "Speech saved to: $OUTPUT_PATH"
echo "$OUTPUT_PATH"
