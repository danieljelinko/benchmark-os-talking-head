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
# activate_conda_env() - Activate a conda environment
# ==========================================
# Args:
#   $1: Environment name
# Returns: 0 on success, 1 on failure
activate_conda_env() {
    local env_name="$1"

    # Source conda shell hook
    if [ -f "$HOME/miniconda/etc/profile.d/conda.sh" ]; then
        source "$HOME/miniconda/etc/profile.d/conda.sh"
    elif [ -f "$HOME/anaconda3/etc/profile.d/conda.sh" ]; then
        source "$HOME/anaconda3/etc/profile.d/conda.sh"
    else
        echo "ERROR: Could not find conda.sh. Is conda installed?"
        return 1
    fi

    # Check if environment exists
    if ! conda env list | grep -q "^${env_name} "; then
        echo "ERROR: Conda environment '$env_name' does not exist."
        echo "Available environments:"
        conda env list
        return 1
    fi

    # Activate environment
    echo "Activating conda environment: $env_name"
    conda activate "$env_name"
    return 0
}
