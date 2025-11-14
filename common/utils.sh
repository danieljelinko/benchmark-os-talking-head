#!/bin/bash
# ==========================================
# Common Utility Functions
# ==========================================
# This file provides shared utility functions used across the framework.
# Source this file to use the functions in other scripts.
#
# Usage: source common/utils.sh

# ==========================================
# check_gpu() - Verify NVIDIA GPU availability
# ==========================================
# Returns: 0 if GPU is available, 1 otherwise
check_gpu() {
    echo "Checking for NVIDIA GPU..."

    if ! command -v nvidia-smi &> /dev/null; then
        echo "ERROR: nvidia-smi not found. NVIDIA drivers may not be installed."
        return 1
    fi

    if ! nvidia-smi &> /dev/null; then
        echo "ERROR: nvidia-smi failed to execute. Check NVIDIA drivers."
        return 1
    fi

    echo "GPU detected:"
    nvidia-smi --query-gpu=name --format=csv,noheader
    return 0
}

# ==========================================
# download_if_missing() - Download file if it doesn't exist
# ==========================================
# Args:
#   $1: URL to download from
#   $2: Destination file path
# Returns: 0 on success, 1 on failure
download_if_missing() {
    local url="$1"
    local dest="$2"

    if [ -f "$dest" ]; then
        echo "File already exists: $dest"
        echo "Skipping download."
        return 0
    fi

    echo "Downloading $url..."
    echo "Destination: $dest"

    # Create parent directory if needed
    local dest_dir
    dest_dir="$(dirname "$dest")"
    mkdir -p "$dest_dir"

    # Download with curl
    if ! curl -L -o "$dest" "$url"; then
        echo "ERROR: Download failed!"
        return 1
    fi

    echo "Download complete: $dest"
    return 0
}

# ==========================================
# activate_uv_venv() - Activate a UV virtual environment
# ==========================================
# Args:
#   $1: Path to virtual environment directory (containing bin/activate)
# Returns: 0 on success, 1 on failure
activate_uv_venv() {
    local venv_path="$1"
    local activate_script="$venv_path/bin/activate"

    # Check if venv exists
    if [ ! -d "$venv_path" ]; then
        echo "ERROR: Virtual environment not found: $venv_path"
        return 1
    fi

    # Check if activate script exists
    if [ ! -f "$activate_script" ]; then
        echo "ERROR: Activation script not found: $activate_script"
        echo "The virtual environment may be corrupted."
        return 1
    fi

    # Activate environment
    echo "Activating virtual environment: $venv_path"
    source "$activate_script"
    return 0
}

# ==========================================
# create_uv_venv() - Create a UV virtual environment
# ==========================================
# Args:
#   $1: Path where to create venv
#   $2: Python version (e.g., "3.8", "3.10")
# Returns: 0 on success, 1 on failure
create_uv_venv() {
    local venv_path="$1"
    local python_version="$2"

    # Check if UV is available
    if ! command -v uv &> /dev/null; then
        echo "ERROR: UV is not installed."
        echo "Please run: bash bootstrap/install_system_deps.sh"
        return 1
    fi

    # Install Python version if needed
    echo "Ensuring Python $python_version is available..."
    uv python install "$python_version"

    # Create virtual environment
    echo "Creating virtual environment at: $venv_path"
    uv venv --python "$python_version" "$venv_path"

    if [ ! -d "$venv_path" ]; then
        echo "ERROR: Failed to create virtual environment"
        return 1
    fi

    echo "Virtual environment created successfully"
    return 0
}
