#!/bin/bash
set -euo pipefail

# ==========================================
# Unified Entrypoint for Talking Head Solutions
# ==========================================
# Routes commands to the appropriate solution's inference script.
#
# Usage: ./run.sh <solution> [options]
#
# Solutions:
#   sadtalker   - SadTalker (head motion, facial expressions, face enhancement)
#   wav2lip     - Wav2Lip (best lip-sync accuracy, static face)
#   echomimic   - EchoMimic (diffusion-based portrait animation)
#   v_express   - V-Express (Tencent AI Lab's solution)
#   audio2head  - Audio2Head (lightweight one-shot)
#
# Options (passed to solution):
#   --image <path>        : Input image (required)
#   --audio <path>        : Input audio file (optional if --text provided)
#   --text "<text>"       : Text to synthesize (optional if --audio provided)
#   --tts <coqui|piper>   : TTS backend (default: coqui)
#
# Examples:
#   ./run.sh sadtalker --image assets/avatar.jpg --text "Hello world" --tts coqui
#   ./run.sh wav2lip --image assets/avatar.jpg --audio assets/speech.wav
#   ./run.sh echomimic --image assets/avatar.jpg --text "Testing" --tts piper

# Check if at least one argument provided
if [ $# -eq 0 ]; then
    echo "ERROR: No solution specified"
    echo ""
    echo "Usage: $0 <solution> [options]"
    echo ""
    echo "Available solutions:"
    echo "  sadtalker   - SadTalker (head motion, expressions, face enhancement)"
    echo "  wav2lip     - Wav2Lip (best lip-sync, static face)"
    echo "  echomimic   - EchoMimic (diffusion-based animation)"
    echo "  v_express   - V-Express (Tencent AI Lab)"
    echo "  audio2head  - Audio2Head (lightweight one-shot)"
    echo ""
    echo "Common options:"
    echo "  --image <path>        Input image (required)"
    echo "  --audio <path>        Input audio file (optional)"
    echo "  --text \"<text>\"       Text to synthesize (optional)"
    echo "  --tts <coqui|piper>   TTS backend (default: coqui)"
    echo ""
    echo "Examples:"
    echo "  $0 sadtalker --image assets/avatar.jpg --text \"Hello world\""
    echo "  $0 wav2lip --image assets/avatar.jpg --audio assets/speech.wav"
    echo "  $0 echomimic --image assets/avatar.jpg --text \"Test\" --tts piper"
    echo ""
    exit 1
fi

# Extract solution name
SOLUTION="$1"
shift

# Get script directory and change to it
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# Route to appropriate solution
case "$SOLUTION" in
    sadtalker)
        echo "Running SadTalker..."
        bash solutions/sadtalker/infer.sh "$@"
        ;;
    wav2lip)
        echo "Running Wav2Lip..."
        bash solutions/wav2lip/infer.sh "$@"
        ;;
    echomimic)
        echo "Running EchoMimic..."
        bash solutions/echomimic/infer.sh "$@"
        ;;
    v_express)
        echo "Running V-Express..."
        bash solutions/v_express/infer.sh "$@"
        ;;
    audio2head)
        echo "Running Audio2Head..."
        bash solutions/audio2head/infer.sh "$@"
        ;;
    *)
        echo "ERROR: Unknown solution: $SOLUTION"
        echo ""
        echo "Available solutions:"
        echo "  sadtalker, wav2lip, echomimic, v_express, audio2head"
        echo ""
        echo "Run '$0' without arguments for usage information."
        exit 1
        ;;
esac
