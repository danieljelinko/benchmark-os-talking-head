#!/bin/bash
set -euo pipefail

# ==========================================
# Piper TTS Speech Generation Script
# ==========================================
# Generates speech from text using Piper TTS.
#
# Usage: bash tts/say_piper.sh <text> [output_path|--play|-p|--keep|-k|--voice <spec>|--model <spec>] [...]
#
# Args:
#   text: Text to synthesize (required)
#   output_path: Path to save WAV file (optional, default: /tmp/tts_output.wav). First non-flag arg after text.
#   --play / -p: Play the generated WAV after synthesis (and remove it afterward unless --keep is set)
#   --keep / -k: Keep the WAV on disk even when playing
#   --voice / --model: Voice spec or URL to download if missing (see below)
#
# Voices:
#   Models are listed at https://huggingface.co/rhasspy/piper-voices (per-language folders per voice).
#   Examples: en_US-lessac-medium (default), en_US-amy-low, en_GB-southern_english_female-medium, en_US-kusal-medium.
#   Use --voice with a relative HF path (e.g., en/en_US/lessac/medium) or a voice name (en_US-lessac-medium)
#   and the script will download to ~/.cache/piper if it isn't present. Direct URLs to .onnx also work.
#
# Environment Variables:
#   PIPER_VOICE: Path to voice model (default: ~/.cache/piper/en_US-lessac-medium.onnx)
#   PIPER_CACHE_DIR: Override voice cache directory (default: ~/.cache/piper)

TEXT="${1:-}"
OUTPUT_PATH="/tmp/tts_output.wav"
CACHE_DIR="${PIPER_CACHE_DIR:-$HOME/.cache/piper}"
PIPER_HF_BASE="https://huggingface.co/rhasspy/piper-voices/resolve/main"
PIPER_VOICE="${PIPER_VOICE:-$CACHE_DIR/en_US-lessac-medium.onnx}"
PIPER_BIN="${HOME}/.local/bin/piper"
PIPER_LIB_DIR="$(dirname "$PIPER_BIN")"
ESPEAK_DATA_DIR="${ESPEAK_NG_DATA:-$PIPER_LIB_DIR/espeak-ng-data}"
PLAY_AUDIO=false
KEEP_FILE=false
VOICE_SPEC=""

# Parse optional args (output path and flags)
shift || true
OUTPUT_SET=false
while [ $# -gt 0 ]; do
    case "$1" in
        --play|-p)
            PLAY_AUDIO=true
            ;;
        --keep|-k)
            KEEP_FILE=true
            ;;
        --voice=*|--model=*)
            VOICE_SPEC="${1#*=}"
            ;;
        --voice|--model|-m)
            VOICE_SPEC="${2:-}"
            shift
            ;;
        *)
            if [ "$OUTPUT_SET" = false ]; then
                OUTPUT_PATH="$1"
                OUTPUT_SET=true
            else
                echo "WARNING: Unrecognized argument: $1" >&2
            fi
            ;;
    esac
    shift || break
done

# Resolve/download voice if a spec was provided
resolve_voice() {
    local spec="$1"
    if [ -z "$spec" ]; then
        echo "$PIPER_VOICE"
        return
    fi

    mkdir -p "$CACHE_DIR"

    # Local file path
    if [ -f "$spec" ]; then
        echo "$spec"
        return
    fi

    local onnx_url=""
    local json_url=""
    local base_name=""

    # HTTP(S) URL
    if [[ "$spec" =~ ^https?:// ]]; then
        onnx_url="$spec"
        base_name="$(basename "${onnx_url%%\?*}")"
        base_name="${base_name%.onnx}"
        json_url="${onnx_url}.json"
    else
        # Hugging Face relative path or voice name
        local rel="${spec#/}"
        # Try to infer HF path from a voice name like en_US-lessac-medium
        if [[ "$rel" != */* && "$rel" != *.onnx ]]; then
            IFS='-' read -ra parts <<< "$rel"
            if [ "${#parts[@]}" -ge 3 ] && [[ "${parts[0]}" == *_* ]]; then
                local locale="${parts[0]}"
                local lang="${locale%%_*}"
                local quality="${parts[${#parts[@]}-1]}"
                local voice_parts=("${parts[@]:1:${#parts[@]}-2}")
                local voice="${voice_parts[*]}"
                voice="${voice// /-}"
                rel="$lang/$locale/$voice/$quality"
            fi
        fi

        if [[ "$rel" == *.onnx ]]; then
            base_name="$(basename "$rel" .onnx)"
            onnx_url="$PIPER_HF_BASE/$rel"
        else
            # Try to build file name as <locale>-<voice>-<quality>.onnx from path segments
            IFS='/' read -ra segs <<< "$rel"
            if [ "${#segs[@]}" -ge 3 ]; then
                locale="${segs[${#segs[@]}-3]}"
                voice_seg="${segs[${#segs[@]}-2]}"
                quality="${segs[${#segs[@]}-1]}"
                base_name="${locale}-${voice_seg}-${quality}"
            else
                base_name="$(basename "$rel")"
            fi
            onnx_url="$PIPER_HF_BASE/$rel/${base_name}.onnx"
        fi
        json_url="${onnx_url}.json"
    fi

    local onnx_dest="$CACHE_DIR/${base_name}.onnx"
    local json_dest="$CACHE_DIR/${base_name}.onnx.json"

    if [ ! -f "$onnx_dest" ]; then
        echo "Downloading voice model: $onnx_url" >&2
        curl -L -o "$onnx_dest" "$onnx_url"
    fi
    if [ ! -f "$json_dest" ]; then
        echo "Downloading voice metadata: $json_url" >&2
        curl -L -o "$json_dest" "$json_url"
    fi

    echo "$onnx_dest"
}

if [ -n "$VOICE_SPEC" ]; then
    PIPER_VOICE="$(resolve_voice "$VOICE_SPEC")"
fi

# Validate input
if [ -z "$TEXT" ]; then
    echo "ERROR: Text is required"
    echo "Usage: $0 <text> [output_path|--play|-p|--keep|-k|--voice <spec>|--model <spec>] [...]"
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
# Show at most the first 50 chars, add ellipsis if there is more
DISPLAY_TEXT="${TEXT:0:50}"
if [ "${#TEXT}" -gt 50 ]; then
    DISPLAY_TEXT+="..."
fi
echo "  Text: ${DISPLAY_TEXT}"
echo "  Voice: $PIPER_VOICE"
echo "  Output: $OUTPUT_PATH"

export LD_LIBRARY_PATH="${PIPER_LIB_DIR}:${LD_LIBRARY_PATH:-}"
export ESPEAK_NG_DATA="$ESPEAK_DATA_DIR"
echo "$TEXT" | "$PIPER_BIN" --model "$PIPER_VOICE" --output_file "$OUTPUT_PATH"

echo "Speech saved to: $OUTPUT_PATH"
echo "$OUTPUT_PATH"

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
        echo "WARNING: No audio player found (ffplay/aplay/paplay); skipping playback." >&2
    fi
    if [ "$KEEP_FILE" = false ]; then
        rm -f "$OUTPUT_PATH"
        echo "Removed: $OUTPUT_PATH"
    fi
fi
