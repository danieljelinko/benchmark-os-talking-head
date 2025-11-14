# Implementation TODOs: Benchmark Open Source Talking Head Solutions

This document provides a phased, step-by-step implementation plan for building the talking-head benchmarking framework. Each section should be implemented sequentially, with testing after each major component.

---

## Phase 1: Core Infrastructure Setup

### 1.1 Repository Initialization

- [x] Create GitHub repository `benchmark-os-talking-head`
- [x] Initialize with README.md, LICENSE (MIT), and .gitignore
- [x] Create directory structure:
  - [x] `bootstrap/`
  - [x] `common/`
  - [x] `tts/`
  - [x] `solutions/`
  - [x] `assets/` (with .gitkeep)
  - [x] `outputs/` (with .gitkeep)
- [x] Create `.env.example` file
- [x] Push initial structure to GitHub

**Test**: Clone repository to a fresh location and verify directory structure exists.

---

### 1.2 Bootstrap Scripts

#### Script: `bootstrap/install_system_deps.sh`

- [x] Add shebang and error handling (`set -euo pipefail`)
- [x] Update apt package list (`apt-get update`)
- [x] Install system packages:
  - [x] git, git-lfs
  - [x] ffmpeg
  - [x] build-essential, curl, wget
  - [x] python3-dev
  - [x] libsm6, libxext6, libxrender-dev, libgomp1
- [x] Initialize git-lfs (`git lfs install`)
- [x] Call `make_uv.sh` script (migrated from conda to UV)
- [x] Add success message
- [x] Make script executable (`chmod +x`)

**Test**: Run on fresh Ubuntu 22.04 VM and verify all packages install without errors.

---

#### Script: `bootstrap/make_uv.sh` (migrated from make_conda.sh)

- [x] Add shebang and error handling
- [x] Check if UV already installed (skip if exists)
- [x] Download UV installer from official URL
- [x] Install UV to `$HOME/.local/bin` (non-interactive)
- [x] Add UV to PATH in ~/.bashrc
- [x] Display message to restart shell
- [x] Make script executable

**Test**: Run script, then verify `uv --version` works after shell restart.

---

### 1.3 Common Utilities

#### Script: `common/utils.sh`

- [x] Create bash library with shared functions
- [x] Implement `check_gpu()` function:
  - [x] Check if nvidia-smi exists
  - [x] Run nvidia-smi and verify success
  - [x] Display detected GPU name
  - [x] Return appropriate exit code
- [x] Implement `download_if_missing()` function:
  - [x] Check if file exists
  - [x] Skip download if present
  - [x] Create parent directory if needed
  - [x] Download with curl
- [x] Implement UV environment functions (migrated from conda):
  - [x] `activate_uv_venv()` - Activate UV virtual environment
  - [x] `create_uv_venv()` - Create UV virtual environment with specific Python version
  - [x] Error handling if env doesn't exist

**Test**: Source utils.sh and call each function manually to verify behavior.

---

#### Script: `common/ensure_ffmpeg.sh`

- [x] Add shebang and error handling
- [x] Check if ffmpeg command exists
- [x] Display error if not found
- [x] Display ffmpeg path if found
- [x] Make script executable

**Test**: Run script before and after installing ffmpeg; verify correct behavior.

---

#### Script: `common/img_to_silent_video.sh`

- [x] Add shebang and error handling
- [x] Accept parameters: image path, output path, duration, fps
- [x] Validate input image exists
- [x] Use ffmpeg to create silent video:
  - [x] Loop still image (-loop 1)
  - [x] Set duration (-t)
  - [x] Set framerate (-r)
  - [x] Use yuv420p pixel format (compatibility)
  - [x] Use libx264 codec
- [x] Suppress verbose output (keep only errors)
- [x] Echo output path
- [x] Make script executable

**Test**: Run with test image, verify output video plays correctly.

---

#### Script: `common/coqui_tts_say.py`

- [x] Add Python shebang
- [x] Add docstring with usage
- [x] Parse command-line arguments (text, output path, optional model)
- [x] Import TTS library (lazy import)
- [x] Load specified TTS model
- [x] Generate speech from text
- [x] Save to output file
- [x] Print success message
- [x] Add error handling
- [x] Make script executable

**Test**: Run with sample text after Coqui TTS is installed; verify WAV file is created.

---

## Phase 2: Text-to-Speech Backends

### 2.1 Coqui TTS Setup

#### Script: `tts/setup_coqui.sh`

- [x] Add shebang and error handling
- [x] Check if UV venv exists (migrated from conda)
- [x] Create UV virtual environment (python=3.10) if needed
- [x] Activate UV venv
- [x] Install TTS package (`uv pip install TTS`)
- [x] Display success message
- [x] Show how to test (tts --list_models)
- [x] Make script executable

**Test**: Run setup script, then activate env and run `tts --list_models`.

---

#### Script: `tts/say_coqui.sh`

- [x] Add shebang and error handling
- [x] Accept parameters: text, output path (optional), model (optional)
- [x] Set defaults for optional parameters
- [x] Activate UV venv (migrated from conda)
- [x] Get script directory path
- [x] Call `coqui_tts_say.py` with arguments
- [x] Echo output path
- [x] Make script executable

**Test**: Run with test text, verify audio file is generated and playable.

---

### 2.2 Piper TTS Setup

#### Script: `tts/setup_piper.sh`

- [x] Add shebang and error handling
- [x] Create directories: ~/.local/bin, ~/.cache/piper
- [x] Check if piper binary exists
- [x] Download piper binary from GitHub releases
- [x] Extract tarball
- [x] Move binary to ~/.local/bin
- [x] Make binary executable
- [x] Clean up temporary files
- [x] Download voice model (.onnx) from Hugging Face
- [x] Download voice config (.json) from Hugging Face
- [x] Add ~/.local/bin to PATH in ~/.bashrc (if not present)
- [x] Display success and test command
- [x] Make script executable

**Test**: Run setup, then test with: `echo 'Hello' | piper --model ~/.cache/piper/en_US-lessac-medium.onnx --output_file /tmp/test.wav`

---

#### Script: `tts/say_piper.sh`

- [x] Add shebang and error handling
- [x] Accept parameters: text, output path (optional)
- [x] Set default output path
- [x] Use PIPER_VOICE env var or default path
- [x] Check if voice model file exists
- [x] Echo text and pipe to piper binary
- [x] Specify model and output file
- [x] Echo output path
- [x] Make script executable

**Test**: Run with test text, verify audio file is generated and playable.

---

## Phase 3: Solution Implementations

Each solution follows the same pattern: setup.sh creates environment and downloads weights; infer.sh provides standardized inference interface. All solutions migrated to UV.

### 3.1 SadTalker

#### Script: `solutions/sadtalker/setup.sh`

- [x] Add shebang and error handling
- [x] Check if UV is available
- [x] Get solution directory path
- [x] Define repo directory path
- [x] Check if repo already cloned
- [x] Clone SadTalker from GitHub if needed
- [x] Change to repo directory
- [x] Check if UV venv exists (migrated from conda)
- [x] Create UV virtual environment (python=3.8) if needed
- [x] Activate UV venv
- [x] Install PyTorch 1.12.1+cu113 with specific index URL
- [x] Install requirements from requirements.txt
- [x] Run model download script (scripts/download_models.sh)
- [x] Display success message
- [x] Make script executable

**Test**: Run setup script, verify environment exists and model checkpoints downloaded.

---

#### Script: `solutions/sadtalker/infer.sh`

- [x] Add shebang and error handling
- [x] Activate UV venv (migrated from conda)
- [x] Get solution and repo directory paths
- [x] Initialize argument variables (img, aud, text, tts)
- [x] Parse command-line arguments with while loop:
  - [x] --image
  - [x] --audio
  - [x] --text
  - [x] --tts
- [x] Validate --image is provided
- [x] If text provided and no audio:
  - [x] Call appropriate TTS script (piper or coqui)
  - [x] Capture audio file path
- [x] Validate audio or text was provided
- [x] Create output directory
- [x] Run SadTalker inference.py with arguments:
  - [x] --driven_audio
  - [x] --source_image
  - [x] --result_dir
  - [x] --preprocess full
  - [x] --still
  - [x] --enhancer gfpgan
- [x] Display success message and output location
- [x] List output files
- [x] Make script executable

**Test**: Run with test image and text; verify video is generated in outputs/sadtalker/.

---

### 3.2 Wav2Lip

#### Script: `solutions/wav2lip/setup.sh`

- [x] Add shebang and error handling
- [x] Check if UV is available
- [x] Get solution and repo directory paths
- [x] Check if repo already cloned
- [x] Clone Wav2Lip from GitHub if needed
- [x] Change to repo directory
- [x] Check if UV venv exists (migrated from conda)
- [x] Create UV virtual environment (python=3.8) if needed
- [x] Activate UV venv
- [x] Install requirements from requirements.txt
- [x] Create directories: checkpoints, face_detection/detection/sfd
- [x] Download wav2lip_gan.pth checkpoint (with fallback message)
- [x] Download wav2lip.pth checkpoint (with fallback message)
- [x] Download s3fd.pth face detector (with fallback message)
- [x] Display success message and manual download note
- [x] Make script executable

**Test**: Run setup script, verify environment and checkpoints (manual download may be needed).

---

#### Script: `solutions/wav2lip/infer.sh`

- [x] Add shebang and error handling
- [x] Activate UV venv (migrated from conda)
- [x] Get solution and repo directory paths
- [x] Initialize argument variables
- [x] Parse command-line arguments (including --checkpoint option)
- [x] Validate --image is provided
- [x] Generate audio from text if needed (call TTS)
- [x] Validate audio is available
- [x] Call ensure_ffmpeg.sh
- [x] Convert image to silent video using img_to_silent_video.sh
- [x] Create output directory and define output path
- [x] Change to repo directory
- [x] Run Wav2Lip inference.py with arguments:
  - [x] --checkpoint_path
  - [x] --face (video file)
  - [x] --audio
  - [x] --outfile
- [x] Display success message and output location
- [x] List output file
- [x] Make script executable

**Test**: Run with test image and text; verify video is generated in outputs/wav2lip/.

---

### 3.3 EchoMimic

#### Script: `solutions/echomimic/setup.sh`

- [x] Add shebang and error handling
- [x] Check if UV is available
- [x] Get solution and repo directory paths
- [x] Check if repo already cloned
- [x] Clone EchoMimic from GitHub if needed
- [x] Change to repo directory
- [x] Check if UV venv exists (migrated from conda)
- [x] Create UV virtual environment (python=3.8) if needed
- [x] Activate UV venv
- [x] Install requirements from requirements.txt
- [x] Initialize git-lfs
- [x] Check if pretrained_weights directory exists
- [x] Clone weights from Hugging Face if needed
- [x] Display success message
- [x] Make script executable

**Test**: Run setup script, verify environment and pretrained_weights directory exists.

---

#### Script: `solutions/echomimic/infer.sh`

- [x] Add shebang and error handling
- [x] Activate UV venv (migrated from conda)
- [x] Get solution and repo directory paths
- [x] Initialize argument variables
- [x] Parse command-line arguments
- [x] Validate --image is provided
- [x] Generate audio from text if needed (call TTS)
- [x] Validate audio is available
- [x] Create temporary config YAML file
- [x] Write test_cases structure with image and audio paths
- [x] Create output directory
- [x] Change to repo directory
- [x] Run infer_audio2vid.py with --config argument
- [x] Display success message
- [x] Make script executable

**Test**: Run with test image and text; verify video is generated (check repo output dirs).

---

### 3.4 V-Express

#### Script: `solutions/v_express/setup.sh`

- [x] Add shebang and error handling
- [x] Check if UV is available
- [x] Get solution and repo directory paths
- [x] Check if repo already cloned
- [x] Clone V-Express from GitHub if needed
- [x] Change to repo directory
- [x] Check if UV venv exists (migrated from conda)
- [x] Create UV virtual environment (python=3.10) if needed
- [x] Activate UV venv
- [x] Install requirements from requirements.txt
- [x] Initialize git-lfs
- [x] Check if model_ckpts directory exists
- [x] Clone model weights from Hugging Face if needed
- [x] Move model_ckpts to correct location
- [x] Clean up temporary directory
- [x] Display success message
- [x] Make script executable

**Test**: Run setup script, verify environment and model_ckpts directory exists.

---

#### Script: `solutions/v_express/infer.sh`

- [x] Add shebang and error handling
- [x] Activate UV venv (migrated from conda)
- [x] Get solution and repo directory paths
- [x] Initialize argument variables
- [x] Parse command-line arguments
- [x] Validate --image is provided
- [x] Generate audio from text if needed (call TTS)
- [x] Validate audio is available
- [x] Create output directory
- [x] Change to repo directory
- [x] Run inference.py with arguments:
  - [x] --reference_image_path (or appropriate flag from V-Express README)
  - [x] --audio_path
  - [x] --output_path
- [x] Display success message and output location
- [x] List output files
- [x] Make script executable

**Test**: Run with test image and text; verify video is generated in outputs/v_express/.

---

### 3.5 Audio2Head

#### Script: `solutions/audio2head/setup.sh`

- [x] Add shebang and error handling
- [x] Check if UV is available
- [x] Get solution and repo directory paths
- [x] Check if repo already cloned
- [x] Clone Audio2Head from GitHub if needed
- [x] Change to repo directory
- [x] Check if UV venv exists (migrated from conda)
- [x] Create UV virtual environment (python=3.8) if needed
- [x] Activate UV venv
- [x] Install requirements from requirements.txt
- [x] Create checkpoints directory
- [x] Display manual download instructions:
  - [x] Show Google Drive link from README
  - [x] Show target checkpoint path
- [x] Display success message
- [x] Make script executable

**Test**: Run setup script, verify environment exists (manual checkpoint download required).

---

#### Script: `solutions/audio2head/infer.sh`

- [x] Add shebang and error handling
- [x] Activate UV venv (migrated from conda)
- [x] Get solution and repo directory paths
- [x] Initialize argument variables
- [x] Parse command-line arguments
- [x] Validate --image is provided (note: must be square-cropped)
- [x] Generate audio from text if needed (call TTS)
- [x] Validate audio is available
- [x] Change to repo directory
- [x] Run inference.py with arguments:
  - [x] --audio_path
  - [x] --img_path
- [x] Display success message
- [x] Make script executable

**Test**: Run with square-cropped test image and audio; verify video is generated.

---

## Phase 4: Unified Entrypoint

### Script: `run.sh`

- [x] Add shebang and error handling
- [x] Check if at least one argument provided
- [x] Display usage message if no arguments:
  - [x] List available solutions
  - [x] Show example commands
- [x] Extract solution name from first argument
- [x] Shift arguments
- [x] Get script directory and change to it
- [x] Use case statement to route to solution:
  - [x] sadtalker → bash solutions/sadtalker/infer.sh "$@"
  - [x] wav2lip → bash solutions/wav2lip/infer.sh "$@"
  - [x] echomimic → bash solutions/echomimic/infer.sh "$@"
  - [x] v_express → bash solutions/v_express/infer.sh "$@"
  - [x] audio2head → bash solutions/audio2head/infer.sh "$@"
  - [x] * → display error for unknown solution
- [x] Make script executable

**Test**: Run `./run.sh` with no args (verify usage message), then run each solution via run.sh.

---

## Phase 5: Documentation and Configuration

### File: `.gitignore`

- [x] Add Python patterns (__pycache__, *.pyc, etc.)
- [x] Add UV venv patterns (migrated from conda)
- [x] Ignore solution repos (solutions/*/repo/)
- [x] Ignore model weights (*.pth, *.onnx, *.bin, etc.)
- [x] Ignore pretrained_weights and checkpoints directories
- [x] Ignore outputs (*.mp4, *.wav, outputs/)
- [x] Ignore temporary files (/tmp/, *.tmp, *.log)
- [x] Ignore IDE files (.vscode/, .idea/, *.swp)
- [x] Ignore OS files (.DS_Store, Thumbs.db)
- [x] Keep .gitkeep files (!outputs/.gitkeep, !assets/.gitkeep)

**Test**: Create dummy files matching patterns and verify they're ignored by git.

---

### File: `.env.example`

- [x] Add TTS_BACKEND variable (default: coqui)
- [x] Add PIPER_VOICE variable with default path
- [x] Add CUDA_VISIBLE_DEVICES variable (default: 0)
- [x] Add comments explaining each variable

**Test**: Copy to .env and source it; verify variables are set.

---

### File: `LICENSE`

- [x] Add MIT License text
- [x] Update copyright year and name
- [x] Add section noting individual solution licenses
- [x] List each solution with link to their license

**Test**: Visual review; ensure proper formatting.

---

### File: `README.md`

(Already created in previous steps - verified completeness)

- [x] Review and ensure all sections are complete
- [x] Verify example commands are correct
- [x] Check all links are valid
- [x] Ensure repository structure matches actual structure
- [x] Verify troubleshooting section is comprehensive
- [x] Updated all references from Conda to UV

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

- [x] All Phase 1-5 implementation tasks are checked off
- [x] All scripts migrated from Conda to UV
- [x] Documentation updated to reflect UV migration
- [x] Repository is properly licensed and attributed
- [ ] Fresh Ubuntu 22.04 + GPU instance can run full pipeline (requires user testing)
- [ ] At least 3 out of 5 solutions successfully generate video (requires user testing)
- [ ] Documentation is clear enough for non-expert to follow (requires user testing)
- [ ] CI/CD pipeline validates basic functionality (optional, future enhancement)

**Note**: Phases 6-8 (Testing, Deployment, Release) require GPU hardware testing by the user on localhost.

---

## Notes for AI Agent Implementation

### Critical Information for Agent

1. **Sequential Implementation**: Implement phases in order. Don't skip ahead.

2. **Error Handling**: Every bash script must start with `set -euo pipefail`.

3. **Path Management**: Always use absolute paths or properly resolve relative paths with `$(cd "$(dirname "$0")" && pwd)`.

4. **UV Virtual Environment Isolation**: Each solution gets its own UV virtual environment (.venv) to avoid dependency conflicts.

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

- **Don't** mix virtual environments (always activate correct venv before installing packages)
- **Don't** use relative paths in scripts that may be called from different directories
- **Don't** assume model URLs remain stable (add error handling)
- **Don't** commit model weights to git (use .gitignore)
- **Don't** skip testing after each component
- **Don't** forget to handle both text and audio input modes
- **Don't** forget to make scripts executable (`chmod +x`)

### Testing Protocol

After implementing each solution:

1. Run `bash solutions/<solution>/setup.sh`
2. Verify UV venv created: `ls solutions/<solution>/.venv/`
3. Verify model weights downloaded: `ls solutions/<solution>/repo/checkpoints/` (or equivalent)
4. Run `./run.sh <solution> --image assets/test.jpg --text "Test" --tts coqui`
5. Verify output exists: `ls outputs/<solution>/`
6. Play video and visually inspect quality
7. Check for errors in console output
8. Document any issues or deviations from plan

### Recommended Implementation Order

1. Bootstrap infrastructure first (get UV and system deps working)
2. Implement common utilities (needed by all solutions)
3. Implement one TTS backend (Coqui recommended first)
4. Implement SadTalker (most complete, good for testing)
5. Implement run.sh entrypoint
6. Test end-to-end with SadTalker
7. Implement remaining solutions one by one
8. Add second TTS backend (Piper)
9. Comprehensive testing across all solutions
10. Documentation polish
11. **COMPLETED**: Migrate all scripts from Conda to UV

---

## Completion Checklist

Before considering the project complete:

- [x] All scripts are executable and have proper shebangs
- [x] All scripts handle errors gracefully (set -euo pipefail)
- [x] All UV virtual environments are properly isolated
- [x] All solutions can be installed via single setup.sh command
- [x] All solutions can be run via unified run.sh interface
- [x] Both TTS backends (Coqui and Piper) work correctly (implementation complete)
- [x] README provides clear quick-start instructions
- [x] All manual download requirements are clearly documented
- [x] .gitignore prevents committing large files
- [x] LICENSE file is present and correct
- [x] Repository is pushed to GitHub
- [x] All scripts migrated from Conda to UV
- [x] UV_MIGRATION_PLAN.md created documenting migration strategy
- [ ] Test image and audio samples are provided in assets/ (user to provide)
- [ ] At least one complete end-to-end test has been performed (requires GPU, user testing)
- [ ] Performance characteristics are documented (time, VRAM) (requires GPU, user testing)
- [ ] Known limitations are documented (requires testing results)

---

**End of TODOs.md**

*This document should be updated as implementation progresses. Check off completed items and add notes about any deviations from the plan.*
