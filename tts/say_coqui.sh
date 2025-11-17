#!/bin/bash
set -euo pipefail

# ==========================================
# Coqui TTS Speech Generation Script
# ==========================================
# Generates speech from text using Coqui TTS.
#
# Usage: bash tts/say_coqui.sh <text> [output_path] [model_name|--play|-p|--keep|-k] [--play|-p|--keep|-k]
#
# Args:
#   text: Text to synthesize (required)
#   output_path: Path to save WAV file (optional, default: /tmp/tts_output.wav)
#   model_name: TTS model name (optional, default: tts_models/en/ljspeech/tacotron2-DDC)
#   --play / -p: Play the generated WAV after synthesis (and remove it afterward unless --keep is set)
#   --keep / -k: Keep the WAV on disk even when playing
#
# Models:
#   List available models: `source tts/coqui_env/.venv/bin/activate && tts --list_models`
#   Catalog: https://huggingface.co/spaces/coqui-ai/TTS
#   Example models: tts_models/en/ljspeech/tacotron2-DDC (default), tts_models/en/ljspeech/vits, tts_models/multilingual/multi-dataset/xtts_v2

DEFAULT_MODEL="tts_models/en/ljspeech/tacotron2-DDC"

TEXT="${1:-}"
OUTPUT_PATH="${2:-/tmp/tts_output.wav}"
MODEL_NAME="$DEFAULT_MODEL"
PLAY_AUDIO=false
KEEP_FILE=false

# Parse optional model / play / keep flags and positional output/model
shift || true
OUTPUT_SET=false
MODEL_SET=false
for ARG in "$@"; do
    case "$ARG" in
        --play|-p)
            PLAY_AUDIO=true
            ;;
        --keep|-k)
            KEEP_FILE=true
            ;;
        *)
            if [ "$OUTPUT_SET" = false ]; then
                OUTPUT_PATH="$ARG"
                OUTPUT_SET=true
            elif [ "$MODEL_SET" = false ]; then
                MODEL_NAME="$ARG"
                MODEL_SET=true
            else
                echo "WARNING: Unrecognized argument: $ARG" >&2
            fi
            ;;
    esac
done

# Validate input
if [ -z "$TEXT" ]; then
    echo "ERROR: Text is required"
    echo "Usage: $0 <text> [output_path] [model_name|--play|-p|--keep|-k] [--play|-p|--keep|-k]"
    exit 1
fi

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
VENV_PATH="$SCRIPT_DIR/coqui_env/.venv"
LOCAL_BIN="$HOME/.local/bin"
ESPEAK_DATA_DIR="${ESPEAK_NG_DATA:-$LOCAL_BIN/espeak-ng-data}"
ESPEAK_LIB_PATH="${LOCAL_BIN}/libespeak-ng.so.1"

# Check if venv exists
if [ ! -d "$VENV_PATH" ]; then
    echo "ERROR: Coqui TTS virtual environment not found at: $VENV_PATH"
    echo "Please run: bash tts/setup_coqui.sh"
    exit 1
fi

# Activate virtual environment
source "$VENV_PATH/bin/activate"

# Ensure bundled espeak-ng (from Piper) is discoverable
export PATH="$LOCAL_BIN:$PATH"
export LD_LIBRARY_PATH="$LOCAL_BIN:${LD_LIBRARY_PATH:-}"
export ESPEAK_NG_DATA="$ESPEAK_DATA_DIR"
export ESPEAK_DATA_PATH="$ESPEAK_DATA_DIR"
export ESPEAKNG_DATA_PATH="$ESPEAK_DATA_DIR"
if [ -f "$ESPEAK_LIB_PATH" ]; then
    export ESPEAK_LIBRARY="$ESPEAK_LIB_PATH"
    export PHONEMIZER_ESPEAK_LIBRARY="$ESPEAK_LIB_PATH"
    export PHONEMIZER_ESPEAK_PATH="$ESPEAK_DATA_DIR"
fi

python "$REPO_ROOT/common/coqui_tts_say.py" "$TEXT" "$OUTPUT_PATH" "$MODEL_NAME"

# Optionally play audio
if [ "$PLAY_AUDIO" = true ]; then
    echo "Playing: $OUTPUT_PATH"
    if command -v ffplay >/dev/null 2>&1; then
        ffplay -nodisp -autoexit "$OUTPUT_PATH" </dev/null >/dev/null 2>&1 || true
    elif command -v aplay >/dev/null 2>&1; then
        aplay "$OUTPUT_PATH" >/dev/null 2>&1 || true
    elif command -v paplay >/dev/null 2>&1; then
        paplay "$OUTPUT_PATH" >/dev/null 2>&1 || true
    else
        echo "WARNING: No audio player found (looked for ffplay/aplay/paplay); skipping playback." >&2
    fi
    if [ "$KEEP_FILE" = false ]; then
        rm -f "$OUTPUT_PATH"
        echo "Removed: $OUTPUT_PATH"
    fi
fi

echo "$OUTPUT_PATH"
