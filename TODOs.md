# Implementation TODOs: Benchmark Open Source Talking Head Solutions

This document provides a phased, step-by-step implementation plan for building the talking-head benchmarking framework. Each section should be implemented sequentially, with testing after each major component.

---

## Phase 1: Core Infrastructure Setup

### 1.1 Repository Initialization

- [ ] Create GitHub repository `benchmark-os-talking-head`
- [ ] Initialize with README.md, LICENSE (MIT), and .gitignore
- [ ] Create directory structure:
  - [ ] `bootstrap/`
  - [ ] `common/`
  - [ ] `tts/`
  - [ ] `solutions/`
  - [ ] `assets/` (with .gitkeep)
  - [ ] `outputs/` (with .gitkeep)
- [ ] Create `.env.example` file
- [ ] Push initial structure to GitHub

**Test**: Clone repository to a fresh location and verify directory structure exists.

---

### 1.2 Bootstrap Scripts

#### Script: `bootstrap/install_system_deps.sh`

- [ ] Add shebang and error handling (`set -euo pipefail`)
- [ ] Update apt package list (`apt-get update`)
- [ ] Install system packages:
  - [ ] git, git-lfs
  - [ ] ffmpeg
  - [ ] build-essential, curl, wget
  - [ ] python3-dev
  - [ ] libsm6, libxext6, libxrender-dev, libgomp1
- [ ] Initialize git-lfs (`git lfs install`)
- [ ] Call `make_conda.sh` script
- [ ] Add success message
- [ ] Make script executable (`chmod +x`)

**Test**: Run on fresh Ubuntu 22.04 VM and verify all packages install without errors.

---

#### Script: `bootstrap/make_conda.sh`

- [ ] Add shebang and error handling
- [ ] Check if conda already installed (skip if exists)
- [ ] Download Miniconda installer from official URL
- [ ] Install Miniconda to `$HOME/miniconda` (non-interactive)
- [ ] Initialize conda for bash shell
- [ ] Add conda init to ~/.bashrc
- [ ] Display message to restart shell
- [ ] Make script executable

**Test**: Run script, then verify `conda --version` works after shell restart.

---

### 1.3 Common Utilities

#### Script: `common/utils.sh`

- [ ] Create bash library with shared functions
- [ ] Implement `check_gpu()` function:
  - [ ] Check if nvidia-smi exists
  - [ ] Run nvidia-smi and verify success
  - [ ] Display detected GPU name
  - [ ] Return appropriate exit code
- [ ] Implement `download_if_missing()` function:
  - [ ] Check if file exists
  - [ ] Skip download if present
  - [ ] Create parent directory if needed
  - [ ] Download with curl
- [ ] Implement `activate_conda_env()` function:
  - [ ] Source conda shell hook
  - [ ] Activate specified environment
  - [ ] Error handling if env doesn't exist

**Test**: Source utils.sh and call each function manually to verify behavior.

---

#### Script: `common/ensure_ffmpeg.sh`

- [ ] Add shebang and error handling
- [ ] Check if ffmpeg command exists
- [ ] Display error if not found
- [ ] Display ffmpeg path if found
- [ ] Make script executable

**Test**: Run script before and after installing ffmpeg; verify correct behavior.

---

#### Script: `common/img_to_silent_video.sh`

- [ ] Add shebang and error handling
- [ ] Accept parameters: image path, output path, duration, fps
- [ ] Validate input image exists
- [ ] Use ffmpeg to create silent video:
  - [ ] Loop still image (-loop 1)
  - [ ] Set duration (-t)
  - [ ] Set framerate (-r)
  - [ ] Use yuv420p pixel format (compatibility)
  - [ ] Use libx264 codec
- [ ] Suppress verbose output (keep only errors)
- [ ] Echo output path
- [ ] Make script executable

**Test**: Run with test image, verify output video plays correctly.

---

#### Script: `common/coqui_tts_say.py`

- [ ] Add Python shebang
- [ ] Add docstring with usage
- [ ] Parse command-line arguments (text, output path, optional model)
- [ ] Import TTS library (lazy import)
- [ ] Load specified TTS model
- [ ] Generate speech from text
- [ ] Save to output file
- [ ] Print success message
- [ ] Add error handling
- [ ] Make script executable

**Test**: Run with sample text after Coqui TTS is installed; verify WAV file is created.

---

## Phase 2: Text-to-Speech Backends

### 2.1 Coqui TTS Setup

#### Script: `tts/setup_coqui.sh`

- [ ] Add shebang and error handling
- [ ] Source conda shell hook
- [ ] Check if 'tts' conda env exists
- [ ] Create conda environment (python=3.10) if needed
- [ ] Activate tts environment
- [ ] Upgrade pip
- [ ] Install TTS package (`pip install TTS`)
- [ ] Display success message
- [ ] Show how to test (tts --list_models)
- [ ] Make script executable

**Test**: Run setup script, then activate env and run `tts --list_models`.

---

#### Script: `tts/say_coqui.sh`

- [ ] Add shebang and error handling
- [ ] Accept parameters: text, output path (optional), model (optional)
- [ ] Set defaults for optional parameters
- [ ] Source conda shell hook
- [ ] Activate tts environment
- [ ] Get script directory path
- [ ] Call `coqui_tts_say.py` with arguments
- [ ] Echo output path
- [ ] Make script executable

**Test**: Run with test text, verify audio file is generated and playable.

---

### 2.2 Piper TTS Setup

#### Script: `tts/setup_piper.sh`

- [ ] Add shebang and error handling
- [ ] Create directories: ~/.local/bin, ~/.cache/piper
- [ ] Check if piper binary exists
- [ ] Download piper binary from GitHub releases
- [ ] Extract tarball
- [ ] Move binary to ~/.local/bin
- [ ] Make binary executable
- [ ] Clean up temporary files
- [ ] Download voice model (.onnx) from Hugging Face
- [ ] Download voice config (.json) from Hugging Face
- [ ] Add ~/.local/bin to PATH in ~/.bashrc (if not present)
- [ ] Display success and test command
- [ ] Make script executable

**Test**: Run setup, then test with: `echo 'Hello' | piper --model ~/.cache/piper/en_US-lessac-medium.onnx --output_file /tmp/test.wav`

---

#### Script: `tts/say_piper.sh`

- [ ] Add shebang and error handling
- [ ] Accept parameters: text, output path (optional)
- [ ] Set default output path
- [ ] Use PIPER_VOICE env var or default path
- [ ] Check if voice model file exists
- [ ] Echo text and pipe to piper binary
- [ ] Specify model and output file
- [ ] Echo output path
- [ ] Make script executable

**Test**: Run with test text, verify audio file is generated and playable.

---

## Phase 3: Solution Implementations

Each solution follows the same pattern: setup.sh creates environment and downloads weights; infer.sh provides standardized inference interface.

### 3.1 SadTalker

#### Script: `solutions/sadtalker/setup.sh`

- [ ] Add shebang and error handling
- [ ] Source conda shell hook
- [ ] Get solution directory path
- [ ] Define repo directory path
- [ ] Check if repo already cloned
- [ ] Clone SadTalker from GitHub if needed
- [ ] Change to repo directory
- [ ] Check if conda env 'sadtalker' exists
- [ ] Create conda environment (python=3.8) if needed
- [ ] Activate sadtalker environment
- [ ] Install PyTorch 1.12.1+cu113 with specific index URL
- [ ] Install ffmpeg via conda
- [ ] Install requirements from requirements.txt
- [ ] Run model download script (scripts/download_models.sh)
- [ ] Display success message
- [ ] Make script executable

**Test**: Run setup script, verify environment exists and model checkpoints downloaded.

---

#### Script: `solutions/sadtalker/infer.sh`

- [ ] Add shebang and error handling
- [ ] Source conda shell hook and activate sadtalker env
- [ ] Get solution and repo directory paths
- [ ] Initialize argument variables (img, aud, text, tts)
- [ ] Parse command-line arguments with while loop:
  - [ ] --image
  - [ ] --audio
  - [ ] --audio
  - [ ] --text
  - [ ] --tts
- [ ] Validate --image is provided
- [ ] If text provided and no audio:
  - [ ] Call appropriate TTS script (piper or coqui)
  - [ ] Capture audio file path
- [ ] Validate audio or text was provided
- [ ] Create output directory
- [ ] Run SadTalker inference.py with arguments:
  - [ ] --driven_audio
  - [ ] --source_image
  - [ ] --result_dir
  - [ ] --preprocess full
  - [ ] --still
  - [ ] --enhancer gfpgan
- [ ] Display success message and output location
- [ ] List output files
- [ ] Make script executable

**Test**: Run with test image and text; verify video is generated in outputs/sadtalker/.

---

### 3.2 Wav2Lip

#### Script: `solutions/wav2lip/setup.sh`

- [ ] Add shebang and error handling
- [ ] Source conda shell hook
- [ ] Get solution and repo directory paths
- [ ] Check if repo already cloned
- [ ] Clone Wav2Lip from GitHub if needed
- [ ] Change to repo directory
- [ ] Check if conda env 'wav2lip' exists
- [ ] Create conda environment (python=3.8) if needed
- [ ] Activate wav2lip environment
- [ ] Install requirements from requirements.txt
- [ ] Create directories: checkpoints, face_detection/detection/sfd
- [ ] Download wav2lip_gan.pth checkpoint (with fallback message)
- [ ] Download wav2lip.pth checkpoint (with fallback message)
- [ ] Download s3fd.pth face detector (with fallback message)
- [ ] Display success message and manual download note
- [ ] Make script executable

**Test**: Run setup script, verify environment and checkpoints (manual download may be needed).

---

#### Script: `solutions/wav2lip/infer.sh`

- [ ] Add shebang and error handling
- [ ] Source conda shell hook and activate wav2lip env
- [ ] Get solution and repo directory paths
- [ ] Initialize argument variables
- [ ] Parse command-line arguments (including --checkpoint option)
- [ ] Validate --image is provided
- [ ] Generate audio from text if needed (call TTS)
- [ ] Validate audio is available
- [ ] Call ensure_ffmpeg.sh
- [ ] Convert image to silent video using img_to_silent_video.sh
- [ ] Create output directory and define output path
- [ ] Change to repo directory
- [ ] Run Wav2Lip inference.py with arguments:
  - [ ] --checkpoint_path
  - [ ] --face (video file)
  - [ ] --audio
  - [ ] --outfile
- [ ] Display success message and output location
- [ ] List output file
- [ ] Make script executable

**Test**: Run with test image and text; verify video is generated in outputs/wav2lip/.

---

### 3.3 EchoMimic

#### Script: `solutions/echomimic/setup.sh`

- [ ] Add shebang and error handling
- [ ] Source conda shell hook
- [ ] Get solution and repo directory paths
- [ ] Check if repo already cloned
- [ ] Clone EchoMimic from GitHub if needed
- [ ] Change to repo directory
- [ ] Check if conda env 'echomimic' exists
- [ ] Create conda environment (python=3.8) if needed
- [ ] Activate echomimic environment
- [ ] Install requirements from requirements.txt
- [ ] Initialize git-lfs
- [ ] Check if pretrained_weights directory exists
- [ ] Clone weights from Hugging Face if needed
- [ ] Display success message
- [ ] Make script executable

**Test**: Run setup script, verify environment and pretrained_weights directory exists.

---

#### Script: `solutions/echomimic/infer.sh`

- [ ] Add shebang and error handling
- [ ] Source conda shell hook and activate echomimic env
- [ ] Get solution and repo directory paths
- [ ] Initialize argument variables
- [ ] Parse command-line arguments
- [ ] Validate --image is provided
- [ ] Generate audio from text if needed (call TTS)
- [ ] Validate audio is available
- [ ] Create temporary config YAML file
- [ ] Write test_cases structure with image and audio paths
- [ ] Create output directory
- [ ] Change to repo directory
- [ ] Run infer_audio2vid.py with --config argument
- [ ] Display success message
- [ ] Make script executable

**Test**: Run with test image and text; verify video is generated (check repo output dirs).

---

### 3.4 V-Express

#### Script: `solutions/v_express/setup.sh`

- [ ] Add shebang and error handling
- [ ] Source conda shell hook
- [ ] Get solution and repo directory paths
- [ ] Check if repo already cloned
- [ ] Clone V-Express from GitHub if needed
- [ ] Change to repo directory
- [ ] Check if conda env 'vexpress' exists
- [ ] Create conda environment (python=3.10) if needed
- [ ] Activate vexpress environment
- [ ] Install requirements from requirements.txt
- [ ] Initialize git-lfs
- [ ] Check if model_ckpts directory exists
- [ ] Clone model weights from Hugging Face if needed
- [ ] Move model_ckpts to correct location
- [ ] Clean up temporary directory
- [ ] Display success message
- [ ] Make script executable

**Test**: Run setup script, verify environment and model_ckpts directory exists.

---

#### Script: `solutions/v_express/infer.sh`

- [ ] Add shebang and error handling
- [ ] Source conda shell hook and activate vexpress env
- [ ] Get solution and repo directory paths
- [ ] Initialize argument variables
- [ ] Parse command-line arguments
- [ ] Validate --image is provided
- [ ] Generate audio from text if needed (call TTS)
- [ ] Validate audio is available
- [ ] Create output directory
- [ ] Change to repo directory
- [ ] Run inference.py with arguments:
  - [ ] --reference_image_path (or appropriate flag from V-Express README)
  - [ ] --audio_path
  - [ ] --output_path
- [ ] Display success message and output location
- [ ] List output files
- [ ] Make script executable

**Test**: Run with test image and text; verify video is generated in outputs/v_express/.

---

### 3.5 Audio2Head

#### Script: `solutions/audio2head/setup.sh`

- [ ] Add shebang and error handling
- [ ] Source conda shell hook
- [ ] Get solution and repo directory paths
- [ ] Check if repo already cloned
- [ ] Clone Audio2Head from GitHub if needed
- [ ] Change to repo directory
- [ ] Check if conda env 'audio2head' exists
- [ ] Create conda environment (python=3.8) if needed
- [ ] Activate audio2head environment
- [ ] Install requirements from requirements.txt
- [ ] Create checkpoints directory
- [ ] Display manual download instructions:
  - [ ] Show Google Drive link from README
  - [ ] Show target checkpoint path
- [ ] Display success message
- [ ] Make script executable

**Test**: Run setup script, verify environment exists (manual checkpoint download required).

---

#### Script: `solutions/audio2head/infer.sh`

- [ ] Add shebang and error handling
- [ ] Source conda shell hook and activate audio2head env
- [ ] Get solution and repo directory paths
- [ ] Initialize argument variables
- [ ] Parse command-line arguments
- [ ] Validate --image is provided (note: must be square-cropped)
- [ ] Generate audio from text if needed (call TTS)
- [ ] Validate audio is available
- [ ] Change to repo directory
- [ ] Run inference.py with arguments:
  - [ ] --audio_path
  - [ ] --img_path
- [ ] Display success message
- [ ] Make script executable

**Test**: Run with square-cropped test image and audio; verify video is generated.

---

## Phase 4: Unified Entrypoint

### Script: `run.sh`

- [ ] Add shebang and error handling
- [ ] Check if at least one argument provided
- [ ] Display usage message if no arguments:
  - [ ] List available solutions
  - [ ] Show example commands
- [ ] Extract solution name from first argument
- [ ] Shift arguments
- [ ] Get script directory and change to it
- [ ] Use case statement to route to solution:
  - [ ] sadtalker → bash solutions/sadtalker/infer.sh "$@"
  - [ ] wav2lip → bash solutions/wav2lip/infer.sh "$@"
  - [ ] echomimic → bash solutions/echomimic/infer.sh "$@"
  - [ ] v_express → bash solutions/v_express/infer.sh "$@"
  - [ ] audio2head → bash solutions/audio2head/infer.sh "$@"
  - [ ] * → display error for unknown solution
- [ ] Make script executable

**Test**: Run `./run.sh` with no args (verify usage message), then run each solution via run.sh.

---

## Phase 5: Documentation and Configuration

### File: `.gitignore`

- [ ] Add Python patterns (__pycache__, *.pyc, etc.)
- [ ] Add conda/venv patterns
- [ ] Ignore solution repos (solutions/*/repo/)
- [ ] Ignore model weights (*.pth, *.onnx, *.bin, etc.)
- [ ] Ignore pretrained_weights and checkpoints directories
- [ ] Ignore outputs (*.mp4, *.wav, outputs/)
- [ ] Ignore temporary files (/tmp/, *.tmp, *.log)
- [ ] Ignore IDE files (.vscode/, .idea/, *.swp)
- [ ] Ignore OS files (.DS_Store, Thumbs.db)
- [ ] Keep .gitkeep files (!outputs/.gitkeep, !assets/.gitkeep)

**Test**: Create dummy files matching patterns and verify they're ignored by git.

---

### File: `.env.example`

- [ ] Add TTS_BACKEND variable (default: coqui)
- [ ] Add PIPER_VOICE variable with default path
- [ ] Add CUDA_VISIBLE_DEVICES variable (default: 0)
- [ ] Add comments explaining each variable

**Test**: Copy to .env and source it; verify variables are set.

---

### File: `LICENSE`

- [ ] Add MIT License text
- [ ] Update copyright year and name
- [ ] Add section noting individual solution licenses
- [ ] List each solution with link to their license

**Test**: Visual review; ensure proper formatting.

---

### File: `README.md`

(Already created in previous steps - verify completeness)

- [ ] Review and ensure all sections are complete
- [ ] Verify example commands are correct
- [ ] Check all links are valid
- [ ] Ensure repository structure matches actual structure
- [ ] Verify troubleshooting section is comprehensive

**Test**: Follow README instructions on fresh system to verify accuracy.

---

## Phase 6: Testing and Validation

### 6.1 End-to-End Testing

#### Create test script: `test_all.sh`

- [ ] Add shebang and error handling
- [ ] Create assets directory if needed
- [ ] Define test image path and test text
- [ ] Check if test image exists (error if missing)
- [ ] Define array of solutions
- [ ] Loop through each solution:
  - [ ] Print section header
  - [ ] Run ./run.sh with solution, test image, and text
  - [ ] Capture exit code
  - [ ] Print success or failure
- [ ] Print summary message
- [ ] Make script executable

**Test**: Run test_all.sh after placing a test image; verify all solutions run.

---

### 6.2 Manual Testing Checklist

- [ ] **Bootstrap Test**: Run on fresh Ubuntu 22.04 VM
  - [ ] Run install_system_deps.sh
  - [ ] Verify conda, git-lfs, ffmpeg installed
  - [ ] Restart shell and verify conda in PATH

- [ ] **TTS Test**: Test both backends
  - [ ] Setup Coqui TTS
  - [ ] Generate sample with say_coqui.sh
  - [ ] Setup Piper TTS
  - [ ] Generate sample with say_piper.sh
  - [ ] Compare audio quality

- [ ] **SadTalker Test**:
  - [ ] Run setup
  - [ ] Test with frontal photo + audio file
  - [ ] Test with frontal photo + text (Coqui)
  - [ ] Test with frontal photo + text (Piper)
  - [ ] Test with 3/4 view photo
  - [ ] Test with cartoon avatar
  - [ ] Evaluate output quality

- [ ] **Wav2Lip Test**:
  - [ ] Run setup (handle manual downloads if needed)
  - [ ] Test with frontal photo + audio file
  - [ ] Test with frontal photo + text
  - [ ] Evaluate lip-sync quality

- [ ] **EchoMimic Test**:
  - [ ] Run setup
  - [ ] Test with frontal photo + audio
  - [ ] Test with frontal photo + text
  - [ ] Evaluate output quality

- [ ] **V-Express Test**:
  - [ ] Run setup
  - [ ] Test with frontal photo + audio
  - [ ] Test with frontal photo + text
  - [ ] Evaluate output quality

- [ ] **Audio2Head Test**:
  - [ ] Run setup
  - [ ] Manually download checkpoint
  - [ ] Test with square-cropped photo + audio
  - [ ] Evaluate output quality

- [ ] **Cross-Solution Comparison**:
  - [ ] Use same image and audio for all solutions
  - [ ] Compare processing time
  - [ ] Compare VRAM usage (nvidia-smi)
  - [ ] Compare output quality (lip-sync, motion, artifacts)
  - [ ] Document findings

---

### 6.3 Edge Case Testing

- [ ] Test with very short text (1 word)
- [ ] Test with long text (30+ seconds)
- [ ] Test with low resolution image (256x256)
- [ ] Test with high resolution image (2048x2048)
- [ ] Test with non-frontal face angle
- [ ] Test with multiple faces in image (should select main face)
- [ ] Test with cartoon/anime style avatar
- [ ] Test with partially occluded face (sunglasses, mask)
- [ ] Test with audio containing silence/pauses
- [ ] Test with non-English text (if TTS supports it)

**Document**: Note which solutions handle edge cases best.

---

## Phase 7: Deployment and Documentation

### 7.1 Remote Server Deployment

- [ ] Document SSH setup procedure
- [ ] Document repository cloning on remote server
- [ ] Document running bootstrap on remote GPU instance
- [ ] Document testing GPU availability (nvidia-smi)
- [ ] Document transferring test assets via scp
- [ ] Document running inference remotely
- [ ] Document retrieving results via scp
- [ ] Add troubleshooting section for remote issues

**Test**: Deploy to remote GPU server and verify all steps work.

---

### 7.2 Performance Benchmarking

- [ ] Create benchmarking script that measures:
  - [ ] Processing time per solution
  - [ ] Peak VRAM usage per solution
  - [ ] Output file size per solution
  - [ ] CPU usage per solution
- [ ] Run benchmark with standardized inputs
- [ ] Document results in README or separate BENCHMARKS.md
- [ ] Include hardware specifications used for benchmarks

**Test**: Run benchmark script and verify metrics are captured accurately.

---

### 7.3 Final Documentation Review

- [ ] Review README.md for accuracy and completeness
- [ ] Review plan.md for any missing implementation details
- [ ] Review TODOs.md and ensure all items are complete
- [ ] Add CONTRIBUTING.md with guidelines for adding new solutions
- [ ] Add CHANGELOG.md documenting version history
- [ ] Ensure all scripts have proper comments
- [ ] Ensure all scripts have usage examples in headers
- [ ] Create GitHub wiki pages (optional):
  - [ ] Detailed installation troubleshooting
  - [ ] Quality comparison between solutions
  - [ ] Tips for preparing input images
  - [ ] Voice cloning guide for TTS

**Test**: Have external reviewer follow documentation and report issues.

---

## Phase 8: Release and Maintenance

### 8.1 GitHub Release

- [ ] Tag repository with v1.0.0
- [ ] Create GitHub release with:
  - [ ] Release notes
  - [ ] Known issues
  - [ ] Example outputs (videos/GIFs)
  - [ ] Link to documentation
- [ ] Add repository topics/tags for discoverability
- [ ] Add shields/badges to README (license, Python version, etc.)

---

### 8.2 Future Enhancements (Post-v1.0)

- [ ] Add Docker support for each solution
- [ ] Add web interface for easy testing (Gradio/Streamlit)
- [ ] Add batch processing support
- [ ] Add video input support (animate existing video, not just images)
- [ ] Add body motion synthesis (Phase 3: Face → Body)
- [ ] Add quality metrics (automatic lip-sync scoring, PSNR, SSIM)
- [ ] Add model fine-tuning guides for cartoon styles
- [ ] Add multi-language TTS support
- [ ] Add real-time inference mode (if feasible)
- [ ] Add API server mode (REST API endpoints)

---

## Success Criteria

The implementation is complete when:

- [x] All Phase 1-7 tasks are checked off
- [ ] Fresh Ubuntu 22.04 + GPU instance can run full pipeline
- [ ] At least 3 out of 5 solutions successfully generate video
- [ ] Documentation is clear enough for non-expert to follow
- [ ] Repository is properly licensed and attributed
- [ ] CI/CD pipeline validates basic functionality (optional)

---

## Notes for AI Agent Implementation

### Critical Information for Agent

1. **Sequential Implementation**: Implement phases in order. Don't skip ahead.

2. **Error Handling**: Every bash script must start with `set -euo pipefail`.

3. **Path Management**: Always use absolute paths or properly resolve relative paths with `$(cd "$(dirname "$0")" && pwd)`.

4. **Conda Environment Isolation**: Each solution gets its own conda environment to avoid dependency conflicts.

5. **Download Verification**: Always check if files/repos exist before downloading/cloning.

6. **Testing After Each Phase**: Don't proceed to next phase without verifying current phase works.

7. **Model Weight Sources**:
   - SadTalker: GitHub repo provides download script
   - Wav2Lip: Manual downloads from SharePoint/Drive (provide clear instructions)
   - EchoMimic: Hugging Face (requires git-lfs)
   - V-Express: Hugging Face (requires git-lfs)
   - Audio2Head: Google Drive (manual download required)

8. **PyTorch Version Conflicts**: Each solution may require specific PyTorch/CUDA versions. Keep environments isolated.

9. **FFmpeg Requirements**: Ensure libx264 codec support for video encoding.

10. **Standardized Interface**: All infer.sh scripts must accept:
    - `--image <path>`: Required
    - `--audio <path>`: Optional if --text provided
    - `--text "<string>"`: Optional if --audio provided
    - `--tts <coqui|piper>`: Optional, defaults to coqui

11. **Output Organization**: All outputs go to `outputs/<solution>/` for easy comparison.

12. **Executable Permissions**: After creating shell scripts, run `chmod +x <script>`.

13. **Git Ignore**: Don't commit large model files or generated outputs to git.

14. **Documentation**: Update README if any implementation deviates from plan.

15. **GPU Requirements**: Code should work with CUDA 11.7+ and 8GB+ VRAM at minimum. Document higher requirements where needed.

### Common Pitfalls to Avoid

- **Don't** mix conda environments (always activate correct env before pip install)
- **Don't** use relative paths in scripts that may be called from different directories
- **Don't** assume model URLs remain stable (add error handling)
- **Don't** commit model weights to git (use .gitignore)
- **Don't** skip testing after each component
- **Don't** forget to handle both text and audio input modes
- **Don't** forget to make scripts executable (`chmod +x`)

### Testing Protocol

After implementing each solution:

1. Run `bash solutions/<solution>/setup.sh`
2. Verify conda environment created: `conda env list | grep <solution>`
3. Verify model weights downloaded: `ls solutions/<solution>/repo/checkpoints/` (or equivalent)
4. Run `./run.sh <solution> --image assets/test.jpg --text "Test" --tts coqui`
5. Verify output exists: `ls outputs/<solution>/`
6. Play video and visually inspect quality
7. Check for errors in console output
8. Document any issues or deviations from plan

### Recommended Implementation Order

1. Bootstrap infrastructure first (get conda and system deps working)
2. Implement common utilities (needed by all solutions)
3. Implement one TTS backend (Coqui recommended first)
4. Implement SadTalker (most complete, good for testing)
5. Implement run.sh entrypoint
6. Test end-to-end with SadTalker
7. Implement remaining solutions one by one
8. Add second TTS backend (Piper)
9. Comprehensive testing across all solutions
10. Documentation polish

---

## Completion Checklist

Before considering the project complete:

- [ ] All scripts are executable and have proper shebangs
- [ ] All scripts handle errors gracefully (set -euo pipefail)
- [ ] All conda environments are properly isolated
- [ ] All solutions can be installed via single setup.sh command
- [ ] All solutions can be run via unified run.sh interface
- [ ] Both TTS backends (Coqui and Piper) work correctly
- [ ] Test image and audio samples are provided in assets/
- [ ] README provides clear quick-start instructions
- [ ] All manual download requirements are clearly documented
- [ ] .gitignore prevents committing large files
- [ ] LICENSE file is present and correct
- [ ] Repository is pushed to GitHub and publicly accessible
- [ ] At least one complete end-to-end test has been performed
- [ ] Performance characteristics are documented (time, VRAM)
- [ ] Known limitations are documented

---

**End of TODOs.md**

*This document should be updated as implementation progresses. Check off completed items and add notes about any deviations from the plan.*
