# Implementation Plan: Benchmark Open Source Talking Head Solutions

## Executive Summary

This document outlines the complete implementation plan for building a standardized benchmarking framework to test and compare open-source talking-head generation systems. The framework will enable users to clone a repository onto a remote GPU server, run setup scripts, and quickly test multiple solutions with a unified interface.

## Project Goals

1. **Standardization**: Create a unified interface for testing diverse talking-head solutions
2. **Automation**: Minimize manual intervention through scripted setup and inference
3. **Modularity**: Keep solutions isolated in separate conda environments
4. **Extensibility**: Make it easy to add new solutions
5. **Documentation**: Provide clear usage examples and troubleshooting guides

## Technical Architecture

### Pipeline Overview

The complete text-to-video pipeline consists of three stages:

1. **Text → Speech (TTS)**: Convert input text to audio waveform
   - Optional stage (skipped if user provides audio directly)
   - Backends: Coqui TTS (high quality) or Piper (fast)

2. **Audio → Talking Head**: Animate face with lip-sync and head motion
   - Core stage: the main focus of benchmarking
   - Five solutions: SadTalker, Wav2Lip, EchoMimic, V-Express, Audio2Head

3. **Face → Body** (future): Add torso/gesture animation
   - Not implemented in initial version
   - Could use AnimateAnyone or DreamTalk

### Repository Structure

```
benchmark-os-talking-head/
├── README.md                      # User-facing documentation
├── plan.md                        # This document
├── TODOs.md                       # Phased implementation checklist
├── .env.example                   # Environment configuration template
├── .gitignore                     # Git ignore rules
├── LICENSE                        # MIT license
├── assets/                        # User test inputs
│   └── .gitkeep
├── outputs/                       # Generated videos
│   └── .gitkeep
├── common/                        # Shared utilities
│   ├── utils.sh                   # Bash helper functions
│   ├── img_to_silent_video.sh     # Convert image to silent video (for Wav2Lip)
│   ├── ensure_ffmpeg.sh           # Verify ffmpeg availability
│   └── coqui_tts_say.py           # Python wrapper for Coqui TTS
├── bootstrap/                     # One-time system setup
│   ├── install_system_deps.sh     # Install system packages
│   └── make_conda.sh              # Install/configure Miniconda
├── tts/                           # Text-to-speech backends
│   ├── setup_coqui.sh             # Setup Coqui TTS environment
│   ├── say_coqui.sh               # Generate speech with Coqui
│   ├── setup_piper.sh             # Setup Piper TTS
│   └── say_piper.sh               # Generate speech with Piper
├── solutions/                     # Talking-head solutions
│   ├── sadtalker/
│   │   ├── setup.sh               # Setup SadTalker
│   │   └── infer.sh               # Run inference
│   ├── wav2lip/
│   │   ├── setup.sh
│   │   └── infer.sh
│   ├── echomimic/
│   │   ├── setup.sh
│   │   └── infer.sh
│   ├── v_express/
│   │   ├── setup.sh
│   │   └── infer.sh
│   └── audio2head/
│       ├── setup.sh
│       └── infer.sh
└── run.sh                         # Unified entrypoint
```

## Implementation Details

### Phase 1: Core Infrastructure

#### 1.1 Bootstrap Scripts

**File: `bootstrap/install_system_deps.sh`**

Purpose: Install system-level dependencies required by all solutions.

Implementation:
```bash
#!/usr/bin/env bash
set -euo pipefail

echo "Installing system dependencies..."

# Update package list
sudo apt-get update

# Install essential packages
sudo apt-get install -y \
    git \
    git-lfs \
    ffmpeg \
    build-essential \
    curl \
    wget \
    python3-dev \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1

# Initialize git-lfs
git lfs install

# Install Miniconda
bash "$(dirname "$0")/make_conda.sh"

echo "System dependencies installed successfully."
```

**File: `bootstrap/make_conda.sh`**

Purpose: Install Miniconda if not already present.

Implementation:
```bash
#!/usr/bin/env bash
set -euo pipefail

if command -v conda >/dev/null 2>&1; then
    echo "Conda already installed at: $(which conda)"
    exit 0
fi

echo "Installing Miniconda..."
cd /tmp
curl -fsSLo miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash miniconda.sh -b -p "$HOME/miniconda"

# Initialize conda for bash
eval "$($HOME/miniconda/bin/conda shell.bash hook)"
conda init bash

echo "Miniconda installed. Please restart your shell or run: source ~/.bashrc"
```

#### 1.2 Common Utilities

**File: `common/utils.sh`**

Purpose: Shared bash functions used across scripts.

Implementation:
```bash
#!/usr/bin/env bash

# Check if running with GPU
check_gpu() {
    if ! command -v nvidia-smi >/dev/null 2>&1; then
        echo "WARNING: nvidia-smi not found. GPU may not be available."
        return 1
    fi
    nvidia-smi >/dev/null 2>&1 || {
        echo "ERROR: nvidia-smi failed. Check CUDA drivers."
        return 1
    }
    echo "GPU detected: $(nvidia-smi --query-gpu=name --format=csv,noheader | head -1)"
    return 0
}

# Download file if missing
download_if_missing() {
    local url="$1"
    local dest="$2"
    if [[ -f "$dest" ]]; then
        echo "File already exists: $dest"
        return 0
    fi
    echo "Downloading $url -> $dest"
    mkdir -p "$(dirname "$dest")"
    curl -fsSL -o "$dest" "$url"
}

# Activate conda environment
activate_conda_env() {
    local env_name="$1"
    eval "$(conda shell.bash hook)"
    conda activate "$env_name" || {
        echo "ERROR: Failed to activate conda env: $env_name"
        exit 1
    }
}
```

**File: `common/ensure_ffmpeg.sh`**

Purpose: Verify ffmpeg is installed.

Implementation:
```bash
#!/usr/bin/env bash
set -euo pipefail

if ! command -v ffmpeg >/dev/null 2>&1; then
    echo "ERROR: ffmpeg not found. Run bootstrap/install_system_deps.sh first."
    exit 1
fi

echo "ffmpeg found at: $(which ffmpeg)"
```

**File: `common/img_to_silent_video.sh`**

Purpose: Convert still image to silent video (needed for Wav2Lip).

Implementation:
```bash
#!/usr/bin/env bash
set -euo pipefail

img="$1"
out="${2:-/tmp/still.mp4}"
dur="${3:-5}"
fps="${4:-25}"

if [[ ! -f "$img" ]]; then
    echo "ERROR: Image not found: $img"
    exit 1
fi

echo "Converting image to video: $img -> $out (${dur}s @ ${fps}fps)"
ffmpeg -y -loop 1 -t "$dur" -i "$img" \
    -vf "format=yuv420p" \
    -r "$fps" \
    -pix_fmt yuv420p \
    -c:v libx264 \
    "$out" 2>&1 | grep -E "(error|Error|ERROR)" || true

echo "$out"
```

**File: `common/coqui_tts_say.py`**

Purpose: Python script to generate speech with Coqui TTS.

Implementation:
```python
#!/usr/bin/env python3
"""
Generate speech from text using Coqui TTS.

Usage:
    python coqui_tts_say.py "Text to speak" output.wav [model_name]
"""
import sys
from pathlib import Path

def main():
    if len(sys.argv) < 3:
        print("Usage: python coqui_tts_say.py <text> <output.wav> [model_name]")
        sys.exit(1)

    text = sys.argv[1]
    output_path = sys.argv[2]
    model_name = sys.argv[3] if len(sys.argv) > 3 else "tts_models/en/ljspeech/tacotron2-DDC"

    # Lazy import to speed up script loading
    from TTS.api import TTS

    print(f"Loading TTS model: {model_name}")
    tts = TTS(model_name)

    print(f"Generating speech: '{text}' -> {output_path}")
    tts.tts_to_file(text=text, file_path=output_path)

    print(f"Speech generated successfully: {output_path}")
    return output_path

if __name__ == "__main__":
    main()
```

### Phase 2: Text-to-Speech Backends

#### 2.1 Coqui TTS

**File: `tts/setup_coqui.sh`**

Purpose: Setup Coqui TTS in isolated conda environment.

Implementation:
```bash
#!/usr/bin/env bash
set -euo pipefail

eval "$(conda shell.bash hook)"

echo "Setting up Coqui TTS..."

# Create conda environment
if conda env list | grep -q "^tts "; then
    echo "Conda env 'tts' already exists. Skipping creation."
else
    conda create -y -n tts python=3.10
fi

conda activate tts

# Install Coqui TTS
pip install --upgrade pip
pip install TTS

echo "Coqui TTS setup complete."
echo "Test with: conda activate tts && tts --list_models"
```

**File: `tts/say_coqui.sh`**

Purpose: Generate speech using Coqui TTS.

Implementation:
```bash
#!/usr/bin/env bash
set -euo pipefail

text="$1"
output="${2:-/tmp/coqui_tts.wav}"
model="${3:-tts_models/en/ljspeech/tacotron2-DDC}"

eval "$(conda shell.bash hook)"
conda activate tts

script_dir="$(cd "$(dirname "$0")" && pwd)"
python "$script_dir/../common/coqui_tts_say.py" "$text" "$output" "$model"

echo "$output"
```

#### 2.2 Piper TTS

**File: `tts/setup_piper.sh`**

Purpose: Download and setup Piper TTS binary.

Implementation:
```bash
#!/usr/bin/env bash
set -euo pipefail

echo "Setting up Piper TTS..."

# Create directories
mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.cache/piper"

# Download Piper binary
if [[ -f "$HOME/.local/bin/piper" ]]; then
    echo "Piper binary already exists."
else
    cd /tmp
    curl -fsSLO https://github.com/rhasspy/piper/releases/download/2023.11.14-2/piper_linux_x86_64.tar.gz
    tar xzf piper_linux_x86_64.tar.gz
    mv piper/piper "$HOME/.local/bin/"
    chmod +x "$HOME/.local/bin/piper"
    rm -rf piper piper_linux_x86_64.tar.gz
fi

# Download voice model
if [[ -f "$HOME/.cache/piper/en_US-lessac-medium.onnx" ]]; then
    echo "Piper voice model already exists."
else
    curl -fsSLo "$HOME/.cache/piper/en_US-lessac-medium.onnx" \
        https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/medium/en_US-lessac-medium.onnx
    curl -fsSLo "$HOME/.cache/piper/en_US-lessac-medium.onnx.json" \
        https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/medium/en_US-lessac-medium.onnx.json
fi

# Add to PATH
if ! grep -q '.local/bin' ~/.bashrc; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
fi

echo "Piper TTS setup complete."
echo "Test with: echo 'Hello' | piper --model ~/.cache/piper/en_US-lessac-medium.onnx --output_file /tmp/test.wav"
```

**File: `tts/say_piper.sh`**

Purpose: Generate speech using Piper TTS.

Implementation:
```bash
#!/usr/bin/env bash
set -euo pipefail

text="$1"
output="${2:-/tmp/piper.wav}"
voice="${PIPER_VOICE:-$HOME/.cache/piper/en_US-lessac-medium.onnx}"

if [[ ! -f "$voice" ]]; then
    echo "ERROR: Piper voice not found: $voice"
    echo "Run: bash tts/setup_piper.sh"
    exit 1
fi

echo "$text" | "$HOME/.local/bin/piper" --model "$voice" --output_file "$output"
echo "$output"
```

### Phase 3: Solution Implementations

Each solution follows the same pattern: `setup.sh` creates environment and downloads weights; `infer.sh` provides standardized inference interface.

#### 3.1 SadTalker

**File: `solutions/sadtalker/setup.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail

eval "$(conda shell.bash hook)"

solution_dir="$(cd "$(dirname "$0")" && pwd)"
repo_dir="$solution_dir/repo"

echo "Setting up SadTalker..."

# Clone repository
if [[ -d "$repo_dir" ]]; then
    echo "SadTalker repo already cloned."
else
    git clone https://github.com/OpenTalker/SadTalker.git "$repo_dir"
fi

cd "$repo_dir"

# Create conda environment
if conda env list | grep -q "^sadtalker "; then
    echo "Conda env 'sadtalker' already exists."
else
    conda create -y -n sadtalker python=3.8
fi

conda activate sadtalker

# Install PyTorch (specific version for CUDA 11.3)
pip install torch==1.12.1+cu113 torchvision==0.13.1+cu113 torchaudio==0.12.1 \
    --extra-index-url https://download.pytorch.org/whl/cu113

# Install ffmpeg via conda
conda install -y ffmpeg

# Install dependencies
pip install -r requirements.txt

# Download model weights
bash scripts/download_models.sh

echo "SadTalker setup complete."
```

**File: `solutions/sadtalker/infer.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail

eval "$(conda shell.bash hook)"
conda activate sadtalker

solution_dir="$(cd "$(dirname "$0")" && pwd)"
repo_dir="$solution_dir/repo"

# Parse arguments
img=""
aud=""
text=""
tts="${TTS_BACKEND:-coqui}"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --image) img="$2"; shift 2;;
        --audio) aud="$2"; shift 2;;
        --text) text="$2"; shift 2;;
        --tts) tts="$2"; shift 2;;
        *) echo "Unknown argument: $1"; exit 2;;
    esac
done

# Validate inputs
if [[ -z "$img" ]]; then
    echo "ERROR: --image required"
    exit 1
fi

# Generate audio from text if needed
if [[ -n "$text" && -z "$aud" ]]; then
    if [[ "$tts" == "piper" ]]; then
        aud="$(bash tts/say_piper.sh "$text")"
    else
        aud="$(bash tts/say_coqui.sh "$text")"
    fi
fi

if [[ -z "$aud" ]]; then
    echo "ERROR: --audio or --text required"
    exit 1
fi

# Prepare output directory
outdir="outputs/sadtalker"
mkdir -p "$outdir"

# Run inference
echo "Running SadTalker inference..."
python "$repo_dir/inference.py" \
    --driven_audio "$aud" \
    --source_image "$img" \
    --result_dir "$outdir" \
    --preprocess full \
    --still \
    --enhancer gfpgan

echo "SadTalker inference complete. Results in: $outdir"
ls -lh "$outdir"
```

#### 3.2 Wav2Lip

**File: `solutions/wav2lip/setup.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail

eval "$(conda shell.bash hook)"

solution_dir="$(cd "$(dirname "$0")" && pwd)"
repo_dir="$solution_dir/repo"

echo "Setting up Wav2Lip..."

# Clone repository
if [[ -d "$repo_dir" ]]; then
    echo "Wav2Lip repo already cloned."
else
    git clone https://github.com/Rudrabha/Wav2Lip.git "$repo_dir"
fi

cd "$repo_dir"

# Create conda environment
if conda env list | grep -q "^wav2lip "; then
    echo "Conda env 'wav2lip' already exists."
else
    conda create -y -n wav2lip python=3.8
fi

conda activate wav2lip

# Install dependencies
pip install -r requirements.txt

# Download checkpoints
mkdir -p checkpoints
mkdir -p face_detection/detection/sfd

echo "Downloading Wav2Lip checkpoints..."
echo "Note: You may need to manually download from the README if these fail."

# wav2lip_gan.pth
if [[ ! -f checkpoints/wav2lip_gan.pth ]]; then
    wget --no-check-certificate \
        'https://iiitaphyd-my.sharepoint.com/personal/radrabha_m_research_iiit_ac_in/_layouts/15/download.aspx?share=EdjI7bZlgApMqsVoEUUXpLsBxqXbn5z8VTmoxp55YNDcIA' \
        -O checkpoints/wav2lip_gan.pth || echo "Manual download needed"
fi

# wav2lip.pth
if [[ ! -f checkpoints/wav2lip.pth ]]; then
    wget --no-check-certificate \
        'https://iiitaphyd-my.sharepoint.com/personal/radrabha_m_research_iiit_ac_in/_layouts/15/download.aspx?share=EbAmjXUfvN9Jm4XgCbqO-0sBxHLqj_Z8wrFz2PXjdYYrdg' \
        -O checkpoints/wav2lip.pth || echo "Manual download needed"
fi

# s3fd face detector
if [[ ! -f face_detection/detection/sfd/s3fd.pth ]]; then
    wget --no-check-certificate \
        'https://www.adrianbulat.com/downloads/python-fan/s3fd-619a316812.pth' \
        -O face_detection/detection/sfd/s3fd.pth || echo "Manual download needed"
fi

echo "Wav2Lip setup complete."
echo "If downloads failed, please follow the manual download instructions in the Wav2Lip README."
```

**File: `solutions/wav2lip/infer.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail

eval "$(conda shell.bash hook)"
conda activate wav2lip

solution_dir="$(cd "$(dirname "$0")" && pwd)"
repo_dir="$solution_dir/repo"

# Parse arguments
img=""
aud=""
text=""
tts="${TTS_BACKEND:-coqui}"
ckpt="checkpoints/wav2lip_gan.pth"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --image) img="$2"; shift 2;;
        --audio) aud="$2"; shift 2;;
        --text) text="$2"; shift 2;;
        --tts) tts="$2"; shift 2;;
        --checkpoint) ckpt="$2"; shift 2;;
        *) echo "Unknown argument: $1"; exit 2;;
    esac
done

# Validate inputs
if [[ -z "$img" ]]; then
    echo "ERROR: --image required"
    exit 1
fi

# Generate audio from text if needed
if [[ -n "$text" && -z "$aud" ]]; then
    if [[ "$tts" == "piper" ]]; then
        aud="$(bash tts/say_piper.sh "$text")"
    else
        aud="$(bash tts/say_coqui.sh "$text")"
    fi
fi

if [[ -z "$aud" ]]; then
    echo "ERROR: --audio or --text required"
    exit 1
fi

# Convert image to silent video (Wav2Lip expects video input)
bash common/ensure_ffmpeg.sh
face_video="$(bash common/img_to_silent_video.sh "$img" /tmp/wav2lip_face.mp4 6 25)"

# Prepare output
outdir="outputs/wav2lip"
mkdir -p "$outdir"
output="$outdir/result.mp4"

# Run inference
echo "Running Wav2Lip inference..."
cd "$repo_dir"
python inference.py \
    --checkpoint_path "$ckpt" \
    --face "$face_video" \
    --audio "$aud" \
    --outfile "$output"

echo "Wav2Lip inference complete. Result: $output"
ls -lh "$output"
```

#### 3.3 EchoMimic

**File: `solutions/echomimic/setup.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail

eval "$(conda shell.bash hook)"

solution_dir="$(cd "$(dirname "$0")" && pwd)"
repo_dir="$solution_dir/repo"

echo "Setting up EchoMimic..."

# Clone repository
if [[ -d "$repo_dir" ]]; then
    echo "EchoMimic repo already cloned."
else
    git clone https://github.com/antgroup/echomimic.git "$repo_dir"
fi

cd "$repo_dir"

# Create conda environment
if conda env list | grep -q "^echomimic "; then
    echo "Conda env 'echomimic' already exists."
else
    conda create -y -n echomimic python=3.8
fi

conda activate echomimic

# Install dependencies
pip install -r requirements.txt

# Download pretrained weights via git-lfs
echo "Downloading pretrained weights from Hugging Face..."
git lfs install
if [[ -d pretrained_weights ]]; then
    echo "Weights already downloaded."
else
    git clone https://huggingface.co/BadToBest/EchoMimic pretrained_weights
fi

echo "EchoMimic setup complete."
```

**File: `solutions/echomimic/infer.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail

eval "$(conda shell.bash hook)"
conda activate echomimic

solution_dir="$(cd "$(dirname "$0")" && pwd)"
repo_dir="$solution_dir/repo"

# Parse arguments
img=""
aud=""
text=""
tts="${TTS_BACKEND:-coqui}"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --image) img="$2"; shift 2;;
        --audio) aud="$2"; shift 2;;
        --text) text="$2"; shift 2;;
        --tts) tts="$2"; shift 2;;
        *) echo "Unknown argument: $1"; exit 2;;
    esac
done

# Validate inputs
if [[ -z "$img" ]]; then
    echo "ERROR: --image required"
    exit 1
fi

# Generate audio from text if needed
if [[ -n "$text" && -z "$aud" ]]; then
    if [[ "$tts" == "piper" ]]; then
        aud="$(bash tts/say_piper.sh "$text")"
    else
        aud="$(bash tts/say_coqui.sh "$text")"
    fi
fi

if [[ -z "$aud" ]]; then
    echo "ERROR: --audio or --text required"
    exit 1
fi

# Create config file
cfg="/tmp/echomimic_cfg.yaml"
cat > "$cfg" <<EOF
test_cases:
  "$img":
    - "$aud"
EOF

# Prepare output directory
mkdir -p outputs/echomimic

# Run inference
echo "Running EchoMimic inference..."
cd "$repo_dir"
python -u infer_audio2vid.py --config "$cfg"

echo "EchoMimic inference complete. Check outputs/echomimic/ and repo output directories."
```

#### 3.4 V-Express

**File: `solutions/v_express/setup.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail

eval "$(conda shell.bash hook)"

solution_dir="$(cd "$(dirname "$0")" && pwd)"
repo_dir="$solution_dir/repo"

echo "Setting up V-Express..."

# Clone repository
if [[ -d "$repo_dir" ]]; then
    echo "V-Express repo already cloned."
else
    git clone https://github.com/tencent-ailab/V-Express.git "$repo_dir"
fi

cd "$repo_dir"

# Create conda environment
if conda env list | grep -q "^vexpress "; then
    echo "Conda env 'vexpress' already exists."
else
    conda create -y -n vexpress python=3.10
fi

conda activate vexpress

# Install dependencies
pip install -r requirements.txt

# Download model checkpoints
echo "Downloading V-Express model checkpoints..."
git lfs install
if [[ -d model_ckpts ]]; then
    echo "Model checkpoints already downloaded."
else
    git clone https://huggingface.co/tk93/V-Express tmp_weights
    mv tmp_weights/model_ckpts model_ckpts
    rm -rf tmp_weights
fi

echo "V-Express setup complete."
```

**File: `solutions/v_express/infer.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail

eval "$(conda shell.bash hook)"
conda activate vexpress

solution_dir="$(cd "$(dirname "$0")" && pwd)"
repo_dir="$solution_dir/repo"

# Parse arguments
img=""
aud=""
text=""
tts="${TTS_BACKEND:-coqui}"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --image) img="$2"; shift 2;;
        --audio) aud="$2"; shift 2;;
        --text) text="$2"; shift 2;;
        --tts) tts="$2"; shift 2;;
        *) echo "Unknown argument: $1"; exit 2;;
    esac
done

# Validate inputs
if [[ -z "$img" ]]; then
    echo "ERROR: --image required"
    exit 1
fi

# Generate audio from text if needed
if [[ -n "$text" && -z "$aud" ]]; then
    if [[ "$tts" == "piper" ]]; then
        aud="$(bash tts/say_piper.sh "$text")"
    else
        aud="$(bash tts/say_coqui.sh "$text")"
    fi
fi

if [[ -z "$aud" ]]; then
    echo "ERROR: --audio or --text required"
    exit 1
fi

# Prepare output directory
outdir="outputs/v_express"
mkdir -p "$outdir"

# Run inference
echo "Running V-Express inference..."
cd "$repo_dir"
python inference.py \
    --reference_image_path "$img" \
    --audio_path "$aud" \
    --output_path "$outdir/result.mp4"

echo "V-Express inference complete. Result: $outdir/result.mp4"
ls -lh "$outdir"
```

#### 3.5 Audio2Head

**File: `solutions/audio2head/setup.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail

eval "$(conda shell.bash hook)"

solution_dir="$(cd "$(dirname "$0")" && pwd)"
repo_dir="$solution_dir/repo"

echo "Setting up Audio2Head..."

# Clone repository
if [[ -d "$repo_dir" ]]; then
    echo "Audio2Head repo already cloned."
else
    git clone https://github.com/wangsuzhen/Audio2Head.git "$repo_dir"
fi

cd "$repo_dir"

# Create conda environment
if conda env list | grep -q "^audio2head "; then
    echo "Conda env 'audio2head' already exists."
else
    conda create -y -n audio2head python=3.8
fi

conda activate audio2head

# Install dependencies
pip install -r requirements.txt

# Note about checkpoint
mkdir -p checkpoints
echo ""
echo "=========================================="
echo "MANUAL STEP REQUIRED:"
echo "Download the pretrained checkpoint from:"
echo "https://drive.google.com/file/d/1-xxxxxYYYYY/view (check README for actual link)"
echo "Place it in: $repo_dir/checkpoints/"
echo "=========================================="
echo ""

echo "Audio2Head setup complete (checkpoint download required)."
```

**File: `solutions/audio2head/infer.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail

eval "$(conda shell.bash hook)"
conda activate audio2head

solution_dir="$(cd "$(dirname "$0")" && pwd)"
repo_dir="$solution_dir/repo"

# Parse arguments
img=""
aud=""
text=""
tts="${TTS_BACKEND:-coqui}"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --image) img="$2"; shift 2;;
        --audio) aud="$2"; shift 2;;
        --text) text="$2"; shift 2;;
        --tts) tts="$2"; shift 2;;
        *) echo "Unknown argument: $1"; exit 2;;
    esac
done

# Validate inputs
if [[ -z "$img" ]]; then
    echo "ERROR: --image required (must be square-cropped face)"
    exit 1
fi

# Generate audio from text if needed
if [[ -n "$text" && -z "$aud" ]]; then
    if [[ "$tts" == "piper" ]]; then
        aud="$(bash tts/say_piper.sh "$text")"
    else
        aud="$(bash tts/say_coqui.sh "$text")"
    fi
fi

if [[ -z "$aud" ]]; then
    echo "ERROR: --audio or --text required"
    exit 1
fi

# Run inference
echo "Running Audio2Head inference..."
cd "$repo_dir"
python inference.py \
    --audio_path "$aud" \
    --img_path "$img"

echo "Audio2Head inference complete. Check repo output directories."
```

### Phase 4: Unified Entrypoint

**File: `run.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <solution> [args...]"
    echo ""
    echo "Available solutions:"
    echo "  sadtalker   - SadTalker (head motion + expression)"
    echo "  wav2lip     - Wav2Lip (best lip-sync, no head motion)"
    echo "  echomimic   - EchoMimic (diffusion-based)"
    echo "  v_express   - V-Express (Tencent AI Lab)"
    echo "  audio2head  - Audio2Head (lightweight)"
    echo ""
    echo "Example:"
    echo "  $0 sadtalker --image assets/avatar.jpg --text 'Hello world' --tts coqui"
    echo "  $0 wav2lip --image assets/avatar.jpg --audio assets/speech.wav"
    exit 1
fi

solution="$1"
shift

script_dir="$(cd "$(dirname "$0")" && pwd)"
cd "$script_dir"

case "$solution" in
    sadtalker)
        bash solutions/sadtalker/infer.sh "$@"
        ;;
    wav2lip)
        bash solutions/wav2lip/infer.sh "$@"
        ;;
    echomimic)
        bash solutions/echomimic/infer.sh "$@"
        ;;
    v_express)
        bash solutions/v_express/infer.sh "$@"
        ;;
    audio2head)
        bash solutions/audio2head/infer.sh "$@"
        ;;
    *)
        echo "ERROR: Unknown solution: $solution"
        echo "Available: sadtalker, wav2lip, echomimic, v_express, audio2head"
        exit 2
        ;;
esac
```

### Phase 5: Supporting Files

**File: `.gitignore`**

```gitignore
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
env/
venv/
ENV/
*.egg-info/
dist/
build/

# Conda
.conda/

# Solution repositories (cloned during setup)
solutions/*/repo/

# Model weights and checkpoints
*.pth
*.onnx
*.bin
*.safetensors
pretrained_weights/
checkpoints/
model_ckpts/

# Outputs
outputs/
*.mp4
*.avi
*.wav
*.mp3

# Temporary files
/tmp/
*.tmp
*.log

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Keep structure
!outputs/.gitkeep
!assets/.gitkeep
```

**File: `.env.example`**

```bash
# TTS Backend (coqui or piper)
TTS_BACKEND=coqui

# Piper voice model path (if using Piper)
PIPER_VOICE=$HOME/.cache/piper/en_US-lessac-medium.onnx

# CUDA device (if multiple GPUs)
CUDA_VISIBLE_DEVICES=0
```

**File: `LICENSE`**

```
MIT License

Copyright (c) 2025 [Your Name]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

---

Note: Individual solutions integrated in this framework maintain their own
licenses. Please review each solution's license before use:

- SadTalker: Check https://github.com/OpenTalker/SadTalker
- Wav2Lip: Research/Personal use only - https://github.com/Rudrabha/Wav2Lip
- EchoMimic: Check https://github.com/antgroup/echomimic
- V-Express: Check https://github.com/tencent-ailab/V-Express
- Audio2Head: Check https://github.com/wangsuzhen/Audio2Head
```

## Testing Strategy

### Automated Testing

Create a test script that validates each solution:

**File: `test_all.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "Testing all solutions..."

# Prepare test assets
mkdir -p assets
test_img="assets/test_avatar.jpg"
test_text="Hello, this is a test of the talking head system."

if [[ ! -f "$test_img" ]]; then
    echo "ERROR: Place a test image at: $test_img"
    exit 1
fi

solutions=("sadtalker" "wav2lip" "echomimic" "v_express" "audio2head")

for solution in "${solutions[@]}"; do
    echo ""
    echo "=========================================="
    echo "Testing: $solution"
    echo "=========================================="

    ./run.sh "$solution" --image "$test_img" --text "$test_text" --tts coqui || {
        echo "FAILED: $solution"
        continue
    }

    echo "SUCCESS: $solution"
done

echo ""
echo "Testing complete. Check outputs/ for results."
```

### Manual Testing Checklist

1. **Image Variations**:
   - Frontal face photo (512x512)
   - 3/4 view photo
   - Cartoon avatar
   - Low resolution image
   - High resolution image (1024x1024+)

2. **Audio Variations**:
   - Pre-recorded WAV (16kHz, mono)
   - TTS-generated (Coqui)
   - TTS-generated (Piper)
   - Long audio (30-60s)
   - Short audio (2-5s)

3. **Quality Assessment**:
   - Lip-sync accuracy (1-5 scale)
   - Head motion naturalness (1-5 scale)
   - Visual artifacts (none/minor/major)
   - Identity preservation (1-5 scale)
   - Processing time (seconds)
   - Peak VRAM usage (GB)

## Deployment Considerations

### Remote Server Setup

```bash
# SSH into remote GPU server
ssh user@gpu-server

# Clone repository
git clone https://github.com/YOUR_USERNAME/benchmark-os-talking-head.git
cd benchmark-os-talking-head

# Run bootstrap
bash bootstrap/install_system_deps.sh
source ~/.bashrc

# Install solutions
bash solutions/sadtalker/setup.sh
# ... etc

# Copy test assets via scp
scp local_avatar.jpg user@gpu-server:~/benchmark-os-talking-head/assets/

# Run inference
./run.sh sadtalker --image assets/local_avatar.jpg --text "Test" --tts coqui
```

### Docker Support (Future Enhancement)

Consider adding Dockerfiles for reproducible environments:

```dockerfile
# Dockerfile.sadtalker
FROM nvidia/cuda:11.7.1-cudnn8-devel-ubuntu22.04
# ... setup steps
```

## Performance Expectations

### Processing Time (approximate, on RTX 3090)

- **SadTalker**: 1-2 min for 5s video
- **Wav2Lip**: 30-60s for 5s video
- **EchoMimic**: 2-4 min for 5s video
- **V-Express**: 2-4 min for 5s video
- **Audio2Head**: 1-2 min for 5s video

### VRAM Requirements

- **SadTalker**: 8-10 GB
- **Wav2Lip**: 4-6 GB
- **EchoMimic**: 14-18 GB
- **V-Express**: 14-18 GB
- **Audio2Head**: 6-8 GB

## Troubleshooting Guide

### Common Issues

1. **Conda not in PATH**:
   ```bash
   eval "$(~/miniconda/bin/conda shell.bash hook)"
   conda init bash
   source ~/.bashrc
   ```

2. **Git LFS files not downloaded**:
   ```bash
   git lfs install
   cd solutions/<solution>/repo
   git lfs pull
   ```

3. **CUDA version mismatch**:
   Check CUDA version: `nvcc --version` or `nvidia-smi`
   Adjust PyTorch installation in setup scripts accordingly.

4. **FFmpeg missing codec**:
   ```bash
   ffmpeg -codecs | grep 264
   # Reinstall ffmpeg with h264 support if missing
   ```

5. **Out of memory**:
   - Reduce batch size (if configurable)
   - Use lower resolution input
   - Close other GPU processes

## Extension Guidelines

To add a new solution:

1. Create `solutions/<new_solution>/` directory
2. Implement `setup.sh` following existing patterns
3. Implement `infer.sh` with standardized interface
4. Add case to `run.sh`
5. Update README.md
6. Test with various inputs
7. Document any special requirements

## Success Criteria

The implementation is complete when:

1. All five solutions can be installed via single command
2. All solutions accept the same `--image`, `--audio`, `--text`, `--tts` interface
3. Generated videos are saved to predictable output locations
4. README provides clear usage instructions
5. Bootstrap works on fresh Ubuntu 22.04 GPU instance
6. At least 3 solutions successfully generate video from test inputs

## Timeline Estimate

- Phase 1 (Core Infrastructure): 2-3 hours
- Phase 2 (TTS Backends): 1-2 hours
- Phase 3 (Solutions): 6-8 hours (1-1.5 hours per solution)
- Phase 4 (Unified Entrypoint): 30 minutes
- Phase 5 (Supporting Files): 1 hour
- Testing & Debugging: 3-4 hours

**Total: 13-18 hours** of implementation time for a single developer.

## References

- [SadTalker Paper](https://arxiv.org/abs/2211.12194)
- [Wav2Lip Paper](https://arxiv.org/abs/2008.10010)
- [EchoMimic Repository](https://github.com/antgroup/echomimic)
- [V-Express Repository](https://github.com/tencent-ailab/V-Express)
- [Audio2Head Repository](https://github.com/wangsuzhen/Audio2Head)
- [Coqui TTS Documentation](https://tts.readthedocs.io/)
- [Piper TTS Documentation](https://github.com/rhasspy/piper)
