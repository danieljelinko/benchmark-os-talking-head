#!/bin/bash
set -euo pipefail

# ==========================================
# Piper TTS Setup Script
# ==========================================
# Downloads and installs Piper TTS binary and voice models.
#
# Usage: bash tts/setup_piper.sh

PIPER_VERSION="2023.11.14-2"
PIPER_URL="https://github.com/rhasspy/piper/releases/download/${PIPER_VERSION}/piper_linux_x86_64.tar.gz"
PIPER_DIR="$HOME/.local/bin"
CACHE_DIR="$HOME/.cache/piper"
VOICE_MODEL="en_US-lessac-medium"
VOICE_URL_BASE="https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/medium"

echo "================================================"
echo "Setting up Piper TTS"
echo "================================================"

# Create directories
mkdir -p "$PIPER_DIR"
mkdir -p "$CACHE_DIR"

# Check if piper binary already exists
if [ -f "$PIPER_DIR/piper" ]; then
    echo "Piper binary already exists at $PIPER_DIR/piper"
    echo "Skipping download."
else
    echo "Downloading Piper binary..."
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"

    curl -L -o piper.tar.gz "$PIPER_URL"

    echo "Extracting Piper..."
    tar -xzf piper.tar.gz

    echo "Installing to $PIPER_DIR..."
    mv piper/piper "$PIPER_DIR/"
    chmod +x "$PIPER_DIR/piper"

    echo "Cleaning up..."
    cd - > /dev/null
    rm -rf "$TEMP_DIR"

    echo "Piper binary installed successfully."
fi

# Download voice model if not exists
VOICE_ONNX="$CACHE_DIR/${VOICE_MODEL}.onnx"
VOICE_JSON="$CACHE_DIR/${VOICE_MODEL}.onnx.json"

if [ -f "$VOICE_ONNX" ] && [ -f "$VOICE_JSON" ]; then
    echo "Voice model already exists:"
    echo "  $VOICE_ONNX"
    echo "  $VOICE_JSON"
else
    echo "Downloading voice model: $VOICE_MODEL"

    curl -L -o "$VOICE_ONNX" "${VOICE_URL_BASE}/${VOICE_MODEL}.onnx"
    curl -L -o "$VOICE_JSON" "${VOICE_URL_BASE}/${VOICE_MODEL}.onnx.json"

    echo "Voice model downloaded successfully."
fi

# Add to PATH if not already present
if [[ ":$PATH:" != *":$PIPER_DIR:"* ]]; then
    echo ""
    echo "Adding $PIPER_DIR to PATH..."

    # Add to .bashrc if not present
    if ! grep -q "export PATH=\"\$HOME/.local/bin:\$PATH\"" "$HOME/.bashrc"; then
        echo "" >> "$HOME/.bashrc"
        echo "# Piper TTS" >> "$HOME/.bashrc"
        echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$HOME/.bashrc"
        echo "Added to ~/.bashrc"
    fi

    # Also export for current session
    export PATH="$PIPER_DIR:$PATH"
fi

echo ""
echo "================================================"
echo "Piper TTS installed successfully!"
echo "================================================"
echo ""
echo "Binary location: $PIPER_DIR/piper"
echo "Voice model: $VOICE_ONNX"
echo ""
echo "To test the installation:"
echo "  echo 'Hello world' | $PIPER_DIR/piper --model $VOICE_ONNX --output_file /tmp/test.wav"
echo ""
echo "Or use the wrapper script:"
echo "  bash tts/say_piper.sh \"Hello world\" /tmp/test.wav"
echo ""
echo "NOTE: If piper command is not found, restart your shell or run:"
echo "  source ~/.bashrc"
echo ""
