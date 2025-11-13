#!/usr/bin/env python3
"""
==========================================
Coqui TTS Speech Generation Script
==========================================
Generates speech from text using Coqui TTS.

Usage:
    python common/coqui_tts_say.py <text> <output_path> [model_name]

Args:
    text: Text to synthesize
    output_path: Path to save WAV file
    model_name: Optional TTS model name (default: tts_models/en/ljspeech/tacotron2-DDC)

Example:
    python common/coqui_tts_say.py "Hello world" /tmp/output.wav
"""

import sys
import os
from pathlib import Path


def main():
    # Parse arguments
    if len(sys.argv) < 3:
        print("ERROR: Missing required arguments", file=sys.stderr)
        print("Usage: coqui_tts_say.py <text> <output_path> [model_name]", file=sys.stderr)
        sys.exit(1)

    text = sys.argv[1]
    output_path = sys.argv[2]
    model_name = sys.argv[3] if len(sys.argv) > 3 else "tts_models/en/ljspeech/tacotron2-DDC"

    # Create output directory if needed
    output_dir = os.path.dirname(output_path)
    if output_dir:
        os.makedirs(output_dir, exist_ok=True)

    # Import TTS (lazy import to fail fast if not installed)
    try:
        from TTS.api import TTS
    except ImportError:
        print("ERROR: TTS library not installed", file=sys.stderr)
        print("Please run: bash tts/setup_coqui.sh", file=sys.stderr)
        sys.exit(1)

    # Load TTS model
    print(f"Loading TTS model: {model_name}")
    try:
        tts = TTS(model_name=model_name, progress_bar=False)
    except Exception as e:
        print(f"ERROR: Failed to load TTS model: {e}", file=sys.stderr)
        sys.exit(1)

    # Generate speech
    print(f"Generating speech: '{text[:50]}{'...' if len(text) > 50 else ''}'")
    try:
        tts.tts_to_file(text=text, file_path=output_path)
    except Exception as e:
        print(f"ERROR: Failed to generate speech: {e}", file=sys.stderr)
        sys.exit(1)

    print(f"Speech saved to: {output_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
