#!/bin/bash
set -euo pipefail

# ==========================================
# FFmpeg Verification Script
# ==========================================
# Verifies that ffmpeg is installed and available.
#
# Usage: bash common/ensure_ffmpeg.sh

if ! command -v ffmpeg &> /dev/null; then
    echo "ERROR: ffmpeg not found!"
    echo ""
    echo "Please install ffmpeg:"
    echo "  Ubuntu/Debian: sudo apt-get install ffmpeg"
    echo "  or run: bash bootstrap/install_system_deps.sh"
    exit 1
fi

echo "FFmpeg found: $(which ffmpeg)"
echo "FFmpeg version:"
ffmpeg -version | head -n 1
exit 0
