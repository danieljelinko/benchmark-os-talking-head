#!/bin/bash
set -euo pipefail

# ==========================================
# Coqui TTS Speech Generation Script
# ==========================================
# Generates speech from text using Coqui TTS.
#
# Usage: bash tts/say_coqui.sh <text> [output_path] [model_name]
#
# Args:
#   text: Text to synthesize (required)
#   output_path: Path to save WAV file (optional, default: /tmp/tts_output.wav)
#   model_name: TTS model name (optional, default: tts_models/en/ljspeech/tacotron2-DDC)

TEXT="${1:-}"
OUTPUT_PATH="${2:-/tmp/tts_output.wav}"
MODEL_NAME="${3:-tts_models/en/ljspeech/tacotron2-DDC}"

# Validate input
if [ -z "$TEXT" ]; then
    echo "ERROR: Text is required"
    echo "Usage: $0 <text> [output_path] [model_name]"
    exit 1
fi

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
VENV_PATH="$SCRIPT_DIR/coqui_env/.venv"

# Check if venv exists
if [ ! -d "$VENV_PATH" ]; then
    echo "ERROR: Coqui TTS virtual environment not found at: $VENV_PATH"
    echo "Please run: bash tts/setup_coqui.sh"
    exit 1
fi

# Activate virtual environment
source "$VENV_PATH/bin/activate"

python "$REPO_ROOT/common/coqui_tts_say.py" "$TEXT" "$OUTPUT_PATH" "$MODEL_NAME"

echo "$OUTPUT_PATH"
