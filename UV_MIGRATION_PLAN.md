# UV Migration Plan - Complete Conda Replacement

## Executive Summary

This document outlines the complete migration from Conda to UV (Astral's fast Python package manager) for the talking-head benchmarking framework.

## Why UV?

- **Speed**: 10-100x faster than pip/conda (written in Rust)
- **Better Dependency Resolution**: More reliable than pip
- **Simpler**: Single binary vs full Conda distribution
- **Lockfiles**: Built-in support for reproducible environments
- **Disk Space**: Much smaller footprint than Conda

## Current Conda Usage Analysis

### Where Conda is Used:
1. `bootstrap/make_conda.sh` - Installs Miniconda
2. `bootstrap/install_system_deps.sh` - Calls make_conda.sh
3. All solution `setup.sh` - Creates conda environments, installs dependencies
4. All solution `infer.sh` - Activates conda environments
5. `tts/setup_coqui.sh` - Creates TTS conda environment
6. `tts/say_coqui.sh` - Activates TTS conda environment
7. `setup_all.sh` - Sources conda shell hooks

### Conda-Specific Features Used:
- Environment creation: `conda create -n name python=3.8`
- Environment activation: `conda activate name`
- Package installation: `pip install` (within conda env)
- Python version management: Conda installs specific Python versions
- FFmpeg installation: Only SadTalker uses `conda install ffmpeg`

## UV Architecture Design

### Virtual Environment Structure
```
benchmark-os-talking-head/
├── .venv/                    # Optional: base venv for utilities
├── tts/
│   └── coqui_env/
│       └── .venv/           # Python 3.10 venv for Coqui TTS
├── solutions/
│   ├── sadtalker/
│   │   ├── .venv/           # Python 3.8 venv
│   │   └── repo/            # Cloned repository (no .venv inside)
│   ├── wav2lip/
│   │   ├── .venv/           # Python 3.8 venv
│   │   └── repo/
│   ├── echomimic/
│   │   ├── .venv/           # Python 3.8 venv
│   │   └── repo/
│   ├── v_express/
│   │   ├── .venv/           # Python 3.10 venv
│   │   └── repo/
│   └── audio2head/
│       ├── .venv/           # Python 3.8 venv
│       └── repo/
```

### Python Version Management
UV now supports Python version management:
```bash
# Install specific Python version (UV downloads and manages it)
uv python install 3.8
uv python install 3.10

# Create venv with specific Python
uv venv --python 3.8 .venv
uv venv --python 3.10 .venv
```

### Environment Activation Pattern
```bash
# Old (Conda):
source $HOME/miniconda/etc/profile.d/conda.sh
conda activate sadtalker

# New (UV):
source /path/to/solutions/sadtalker/.venv/bin/activate
```

### Package Installation Pattern
```bash
# Old (Conda + pip):
conda activate env_name
pip install -r requirements.txt

# New (UV):
source .venv/bin/activate
uv pip install -r requirements.txt

# Or without activation:
.venv/bin/pip install -r requirements.txt
# Or even better:
uv pip install -r requirements.txt --python .venv/bin/python
```

## Implementation Strategy

### Phase 1: Bootstrap (Files: 2)
- **Remove**: `bootstrap/make_conda.sh`
- **Update**: `bootstrap/install_system_deps.sh`
  - Remove Miniconda installation
  - Add UV installation via official installer
  - Keep all system packages (git, ffmpeg, build-essential, etc.)

### Phase 2: Common Utilities (Files: 1)
- **Update**: `common/utils.sh`
  - Remove `activate_conda_env()` function
  - Add `activate_uv_venv()` function
  - Keep other utility functions unchanged

### Phase 3: TTS Backends (Files: 2)
- **Update**: `tts/setup_coqui.sh`
  - Create venv at `tts/coqui_env/.venv`
  - Use `uv python install 3.10`
  - Use `uv venv --python 3.10`
  - Use `uv pip install TTS`
- **Update**: `tts/say_coqui.sh`
  - Activate venv from `tts/coqui_env/.venv`
  - Remove conda shell hook sourcing
- **No change**: Piper TTS (uses binary, no Python env needed)

### Phase 4: Solutions (Files: 10)

#### SadTalker (Test First!)
- **Update**: `solutions/sadtalker/setup.sh`
  - Install Python 3.8: `uv python install 3.8`
  - Create venv: `uv venv --python 3.8 .venv`
  - Install PyTorch 1.12.1+cu113 with extra-index-url
  - Remove `conda install ffmpeg` (already in system)
  - Use `uv pip install -r requirements.txt`
- **Update**: `solutions/sadtalker/infer.sh`
  - Replace conda activation with venv source
  - Test inference works

#### Wav2Lip
- Similar to SadTalker (Python 3.8)
- No conda-specific dependencies

#### EchoMimic
- Python 3.8
- Requirements.txt based

#### V-Express
- Python 3.10
- Requirements.txt based

#### Audio2Head
- Python 3.8
- Requirements.txt based

### Phase 5: Master Scripts (Files: 1)
- **Update**: `setup_all.sh`
  - Remove conda shell hook sourcing
  - Update environment checks
  - Update success messages

### Phase 6: Documentation (Files: 2)
- **Update**: `README.md`
  - Replace Conda references with UV
  - Update installation instructions
- **Update**: `.gitignore`
  - Add `.venv/` patterns
  - Remove conda patterns

## PyTorch Installation Strategy

Each solution requires specific PyTorch versions with CUDA support.

### SadTalker (PyTorch 1.12.1+cu113):
```bash
uv pip install torch==1.12.1+cu113 torchvision==0.13.1+cu113 torchaudio==0.12.1 \
    --extra-index-url https://download.pytorch.org/whl/cu113
```

### Modern Solutions (Latest PyTorch):
```bash
# Let requirements.txt handle it, or:
uv pip install torch torchvision torchaudio \
    --extra-index-url https://download.pytorch.org/whl/cu118
```

## Testing Strategy

### Validation Checklist Per Solution:

1. **Setup Phase**:
   - [ ] UV installed successfully
   - [ ] Python version installed correctly
   - [ ] Virtual environment created
   - [ ] All dependencies installed without errors
   - [ ] PyTorch with CUDA available
   - [ ] Repository cloned successfully
   - [ ] Model weights downloaded

2. **Inference Phase**:
   - [ ] Virtual environment activates
   - [ ] Python imports work (torch, solution modules)
   - [ ] GPU detected (nvidia-smi accessible)
   - [ ] TTS generation works
   - [ ] Inference script completes
   - [ ] Output video generated

3. **Integration Testing**:
   - [ ] setup_all.sh completes end-to-end
   - [ ] run.sh routes correctly
   - [ ] Multiple solutions can coexist
   - [ ] No environment conflicts

### Test Sequence:

1. **Unit Test Bootstrap**:
   ```bash
   bash bootstrap/install_system_deps.sh
   uv --version  # Should work
   ```

2. **Unit Test TTS**:
   ```bash
   bash tts/setup_coqui.sh
   bash tts/say_coqui.sh "Test" /tmp/test.wav
   # Verify /tmp/test.wav exists
   ```

3. **Unit Test SadTalker** (Critical!):
   ```bash
   bash solutions/sadtalker/setup.sh
   # Check .venv exists
   # Check PyTorch with CUDA
   source solutions/sadtalker/.venv/bin/activate
   python -c "import torch; print(torch.cuda.is_available())"
   deactivate
   ```

4. **Integration Test**:
   ```bash
   bash setup_all.sh --solutions sadtalker
   ./run.sh sadtalker --image assets/test.jpg --text "Hello"
   # Verify output in outputs/sadtalker/
   ```

5. **Full System Test**:
   ```bash
   bash setup_all.sh
   # Test all solutions with run.sh
   ```

## Rollback Strategy

- All changes committed atomically
- Each commit can be reverted independently
- Old conda branch remains available: `claude/implement-todos-011CV5sE6YzsK3atmoK5LXWY`
- New UV branch: `claude/uv-migration-<session-id>`

## Risk Mitigation

### Risk 1: UV installation fails
- **Mitigation**: Provide alternative installation methods (pip install uv)
- **Fallback**: Manual UV binary download

### Risk 2: Python version not available
- **Mitigation**: Use `uv python list` to check available versions
- **Fallback**: Use system Python with `python3.8` if installed

### Risk 3: PyTorch CUDA mismatch
- **Mitigation**: Explicit --extra-index-url for each solution
- **Testing**: Verify `torch.cuda.is_available()` in each venv

### Risk 4: Dependencies conflict
- **Mitigation**: UV has better resolver than pip
- **Testing**: Run full setup and check for errors

### Risk 5: Activation script fails
- **Mitigation**: Use absolute paths in activation
- **Testing**: Test activation from different directories

## Success Criteria

The migration is successful when:

- [ ] All 22 scripts updated (no conda references)
- [ ] Bootstrap installs UV successfully
- [ ] All TTS backends work with UV venvs
- [ ] All 5 solutions install successfully
- [ ] All 5 solutions run inference successfully
- [ ] setup_all.sh completes without errors
- [ ] run.sh works with all solutions
- [ ] GPU/CUDA accessible in all environments
- [ ] Documentation updated
- [ ] All changes committed and pushed

## Implementation Order

1. ✅ Create this plan document
2. Update bootstrap scripts
3. Update common utilities
4. Update TTS Coqui (test)
5. Update SadTalker (test thoroughly!)
6. Update remaining solutions (if SadTalker works)
7. Update setup_all.sh
8. Update documentation
9. Full integration test
10. Commit and push

## Notes

- Keep .gitignore entries for `.venv/` directories
- Remove conda environment directories from tracking
- UV lockfiles (uv.lock) not needed for this use case (repo clones manage their own deps)
- FFmpeg remains system-level (apt-get only)
- git-lfs remains system-level (apt-get only)

## UV Command Reference

```bash
# Install UV
curl -LsSf https://astral.sh/uv/install.sh | sh

# Install Python version
uv python install 3.8
uv python install 3.10

# List installed Python versions
uv python list

# Create virtual environment
uv venv .venv
uv venv --python 3.8 .venv
uv venv --python 3.10 .venv

# Install packages
uv pip install package_name
uv pip install -r requirements.txt
uv pip install package==version --extra-index-url https://...

# Sync from pyproject.toml (if we had one)
uv sync

# Run command in venv
uv run python script.py
```

---

**Status**: Ready to implement
**Author**: Claude Code Agent
**Date**: 2025-11-14
