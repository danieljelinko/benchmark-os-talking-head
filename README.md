# Benchmark Open Source Talking Head Solutions 251113

A comprehensive testing and benchmarking framework for open-source text-to-video talking head generation systems.

## Goal

This repository provides a standardized framework to evaluate and compare different open-source solutions that animate still images (photos or cartoon avatars) to speak given text or audio. The goal is to enable rapid testing and comparison of multiple talking-head generation systems with a unified interface.

## What This Framework Does

- **Automated Setup**: Each solution has dedicated setup scripts that handle dependency installation, conda environment creation, and model weight downloads
- **Unified Interface**: All solutions use the same command-line interface for inference
- **Text-to-Speech Integration**: Optional TTS backends (Coqui TTS, Piper) allow text-only input
- **Standardized Output**: All results are saved to a consistent directory structure for easy comparison

## Solutions Included

1. **SadTalker** - Most complete solution with head motion, facial expressions, and face enhancement (GFPGAN)
2. **Wav2Lip** - Industry-standard lip-sync accuracy, static face (no head movement)
3. **EchoMimic** - Diffusion-based portrait animation with audio-driven control
4. **V-Express** - Tencent AI Lab's diffusion-based talking head system
5. **Audio2Head** - Lightweight one-shot audio-driven talking head generation

## Requirements

- **OS**: Ubuntu 22.04+ (or similar Linux distribution)
- **GPU**: NVIDIA GPU with CUDA 11.7+ drivers
- **VRAM**: 12+ GB recommended (16+ GB for diffusion models)
- **Disk Space**: ~30-50 GB for all models and dependencies
- **Network**: Outbound HTTPS access to download models from GitHub, Hugging Face, and Google Drive

## Quick Start

### 1. Bootstrap System (One-Time Setup)

```bash
# Clone this repository
git clone https://github.com/YOUR_USERNAME/benchmark-os-talking-head.git
cd benchmark-os-talking-head

# Install system dependencies (git, git-lfs, ffmpeg, miniconda)
bash bootstrap/install_system_deps.sh

# Restart your shell or source your bashrc to get conda on PATH
source ~/.bashrc
```

### 2. Install TTS Backend (Optional, for text input)

```bash
# Option 1: Coqui TTS (high quality, multiple voices)
bash tts/setup_coqui.sh

# Option 2: Piper (fast, lightweight)
bash tts/setup_piper.sh
```

### 3. Install Solution(s)

```bash
# Install all solutions
bash solutions/sadtalker/setup.sh
bash solutions/wav2lip/setup.sh
bash solutions/echomimic/setup.sh
bash solutions/v_express/setup.sh
bash solutions/audio2head/setup.sh

# Or install just one to start
bash solutions/sadtalker/setup.sh
```

### 4. Prepare Test Assets

Place your test files in the `assets/` directory:

```bash
mkdir -p assets
# Copy your avatar image (512x512+ recommended, frontal view)
cp /path/to/your/avatar.jpg assets/
# Optional: Copy audio file
cp /path/to/your/speech.wav assets/
```

### 5. Run Inference

```bash
# Using audio file
./run.sh sadtalker --image assets/avatar.jpg --audio assets/speech.wav

# Using text (requires TTS backend)
./run.sh sadtalker --image assets/avatar.jpg --text "Hello! This is a test." --tts coqui

# Try different solutions
./run.sh wav2lip --image assets/avatar.jpg --text "Testing Wav2Lip" --tts piper
./run.sh echomimic --image assets/avatar.jpg --audio assets/speech.wav
```

### 6. View Results

Generated videos are saved to `outputs/<solution>/`:

```bash
ls -lh outputs/sadtalker/
ls -lh outputs/wav2lip/
# etc.
```

## Usage Examples

```bash
# SadTalker with text input and Coqui TTS
./run.sh sadtalker --image assets/avatar.jpg --text "Welcome to the benchmarking system" --tts coqui

# Wav2Lip with audio file
./run.sh wav2lip --image assets/avatar.jpg --audio assets/speech.wav

# EchoMimic with text and Piper TTS
./run.sh echomimic --image assets/avatar.jpg --text "Testing EchoMimic" --tts piper

# V-Express with audio
./run.sh v_express --image assets/avatar.jpg --audio assets/speech.wav

# Audio2Head (requires square-cropped face image)
./run.sh audio2head --image assets/avatar_square.jpg --audio assets/speech.wav
```

## Testing Strategy

The framework supports comprehensive testing across multiple dimensions:

### Image Types
- Real photos (frontal view)
- 3/4 view photos
- Cartoon/illustrated avatars
- Different resolutions and aspect ratios

### Audio Sources
- Pre-recorded WAV files (16kHz or 22.05kHz)
- TTS-generated audio (Coqui or Piper)
- Different durations (5-10s, 30-60s, longer)

### Evaluation Metrics
- Lip-sync accuracy
- Head motion naturalness
- Artifact presence (mouth seams, double lips, distortion)
- Identity preservation
- Processing speed
- VRAM usage

## Repository Structure

```
benchmark-os-talking-head/
├── README.md                    # This file
├── plan.md                      # Detailed implementation plan
├── TODOs.md                     # Phased implementation checklist
├── .env.example                 # Environment variable template
├── assets/                      # Test inputs (images, audio)
├── outputs/                     # Generated videos
├── common/                      # Shared utilities
│   ├── utils.sh                 # Bash helper functions
│   ├── img_to_silent_video.sh   # FFmpeg: image -> silent video
│   ├── ensure_ffmpeg.sh         # Verify ffmpeg installation
│   └── coqui_tts_say.py         # Python TTS wrapper
├── bootstrap/                   # System-level setup
│   ├── install_system_deps.sh   # Install git, ffmpeg, conda
│   └── make_conda.sh            # Install/configure Miniconda
├── tts/                         # Text-to-speech modules
│   ├── setup_coqui.sh           # Setup Coqui TTS
│   ├── say_coqui.sh             # Generate speech with Coqui
│   ├── setup_piper.sh           # Setup Piper TTS
│   └── say_piper.sh             # Generate speech with Piper
├── solutions/                   # Individual talking-head solutions
│   ├── sadtalker/
│   │   ├── setup.sh             # Setup SadTalker
│   │   └── infer.sh             # Run SadTalker inference
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
└── run.sh                       # Unified entrypoint
```

## Important Notes

### Licensing
- **Wav2Lip**: Research and personal use only (non-commercial license)
- **Other solutions**: Check individual repository licenses before commercial use

### Model Weights
- Most solutions download weights automatically during setup
- Some require manual downloads from Google Drive or SharePoint (script will prompt)
- Weights are stored in each solution's `repo/checkpoints` or `repo/pretrained_weights` directory

### GPU Memory
- **SadTalker, Wav2Lip, Audio2Head**: 8-12 GB VRAM
- **EchoMimic, V-Express**: 16+ GB VRAM recommended

### Cartoon/Illustrated Avatars
Models are primarily trained on real human faces. Cartoon avatars may produce:
- Reduced quality or artifacts
- Less accurate lip-sync
- Style mismatches

For best cartoon results, consider fine-tuning or using images with clear facial features.

## Troubleshooting

### Conda not found after installation
```bash
source ~/.bashrc
# or
eval "$($HOME/miniconda/bin/conda shell.bash hook)"
```

### Git LFS issues
```bash
git lfs install
cd solutions/<solution>/repo
git lfs pull
```

### CUDA/PyTorch version mismatches
Each solution's `setup.sh` installs specific PyTorch versions. Keep environments isolated using conda.

### FFmpeg encoding errors
Ensure FFmpeg is compiled with x264 support:
```bash
ffmpeg -codecs | grep 264
```

## Contributing

Contributions are welcome! To add a new solution:

1. Create a new directory under `solutions/<solution_name>/`
2. Implement `setup.sh` (conda env + dependencies + weights)
3. Implement `infer.sh` (standardized interface with `--image`, `--audio`, `--text`, `--tts`)
4. Add a case to `run.sh`
5. Update this README with solution description
6. Submit a pull request

## References

- [SadTalker GitHub](https://github.com/OpenTalker/SadTalker)
- [Wav2Lip GitHub](https://github.com/Rudrabha/Wav2Lip)
- [EchoMimic GitHub](https://github.com/antgroup/echomimic)
- [V-Express GitHub](https://github.com/tencent-ailab/V-Express)
- [Audio2Head GitHub](https://github.com/wangsuzhen/Audio2Head)
- [Coqui TTS](https://github.com/coqui-ai/TTS)
- [Piper TTS](https://github.com/rhasspy/piper)

## License

This framework itself is MIT licensed. Individual solutions maintain their original licenses. Please review each solution's license before use.

## Citation

If you use this benchmarking framework in research, please cite the individual papers for each solution you evaluate.
