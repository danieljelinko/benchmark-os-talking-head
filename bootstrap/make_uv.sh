#!/bin/bash
set -euo pipefail

# ==========================================
# UV Installation Script
# ==========================================
# Installs UV (fast Python package manager by Astral).
#
# Usage: bash bootstrap/make_uv.sh

UV_INSTALL_SCRIPT="https://astral.sh/uv/install.sh"
UV_BIN="$HOME/.local/bin/uv"

echo "================================================"
echo "UV Installation"
echo "================================================"

# Check if UV is already installed
if command -v uv &> /dev/null; then
    echo "UV is already installed:"
    uv --version
    echo "Skipping installation."
    exit 0
fi

# Check if UV binary exists in expected location
if [ -f "$UV_BIN" ]; then
    echo "UV binary found at $UV_BIN"
    export PATH="$HOME/.local/bin:$PATH"
    if command -v uv &> /dev/null; then
        echo "UV version:"
        uv --version
        echo "Skipping installation."
        exit 0
    fi
fi

# Download and install UV
echo "Downloading and installing UV..."
curl -LsSf "$UV_INSTALL_SCRIPT" | sh

# Add to PATH for current session
export PATH="$HOME/.local/bin:$PATH"

# Verify installation
if command -v uv &> /dev/null; then
    echo ""
    echo "================================================"
    echo "UV installed successfully!"
    echo "================================================"
    echo ""
    uv --version
    echo ""
else
    echo ""
    echo "================================================"
    echo "ERROR: UV installation failed"
    echo "================================================"
    echo ""
    echo "Please install manually:"
    echo "  curl -LsSf https://astral.sh/uv/install.sh | sh"
    echo ""
    echo "Or via pip:"
    echo "  pip install uv"
    echo ""
    exit 1
fi

# Add to PATH in .bashrc if not already present
if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.bashrc"; then
    echo "" >> "$HOME/.bashrc"
    echo "# UV (Python package manager)" >> "$HOME/.bashrc"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
    echo "Added UV to PATH in ~/.bashrc"
fi

echo "NOTE: UV is now available in this session."
echo "For new shells, restart or run: source ~/.bashrc"
echo ""
