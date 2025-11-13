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

# Source conda
if [ -f "$HOME/miniconda/etc/profile.d/conda.sh" ]; then
    source "$HOME/miniconda/etc/profile.d/conda.sh"
elif [ -f "$HOME/anaconda3/etc/profile.d/conda.sh" ]; then
    source "$HOME/anaconda3/etc/profile.d/conda.sh"
else
    echo "ERROR: Could not find conda.sh. Is conda installed?"
    exit 1
fi

# Activate TTS environment
conda activate tts

# Get script directory and call Python TTS script
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

python "$REPO_ROOT/common/coqui_tts_say.py" "$TEXT" "$OUTPUT_PATH" "$MODEL_NAME"

echo "$OUTPUT_PATH"
